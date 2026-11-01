import ComposableArchitecture
import Defaults
import SwiftUI

@Reducer
struct DownloadsFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.downloads) var downloads
        @Shared(.hasDownloads) var hasDownloads
        @Shared(.isDownloaderRunning) var isRunning
    }

    enum Action {
        case launch
        case runningChanged(Bool)
        case commandReceived(DownloadCommand)
        case statusesReceived([StatusResult])
        case started(Download)
        case pauseTapped(gid: String)
        case unpauseTapped(gid: String)
        case removeTapped(gid: String)
        case paused(gid: String)
        case unpaused(gid: String)
        case removed(gid: String)
    }

    private enum CancelID {
        case polling
    }

    @Dependency(\.aria2Client) private var aria2Client
    @Dependency(\.movieDetailsClient) private var movieDetailsClient
    @Dependency(\.selectionHistory) private var selectionHistory
    @Dependency(\.downloadCommands) private var downloadCommands
    @Dependency(\.downloadNotifications) private var notifications
    @Dependency(\.continuousClock) private var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .launch:
                return .merge(
                    .run { _ in
                        notifications.registerCategories()
                    },
                    .run { send in
                        do {
                            try aria2Client.start()

                            await send(.runningChanged(true), animation: .easeInOut)
                            await aria2Client.waitUntilExit()
                        } catch {
                            await LaunchErrors.record(error)
                        }

                        await send(.runningChanged(false), animation: .easeInOut)
                    },
                    .run { send in
                        for await command in downloadCommands.commands() {
                            await send(.commandReceived(command))
                        }
                    },
                    .run { _ in
                        for await count in Defaults.updates(.maxConcurrentDownloads, initial: false) {
                            try? await aria2Client.setMaxConcurrentDownloads(count: count)
                        }
                    }
                )

            case let .runningChanged(isRunning):
                state.$isRunning.withLock { $0 = isRunning }

                return isRunning ? .none : .cancel(id: CancelID.polling)

            case let .commandReceived(.download(data)):
                return download(data)

            case let .commandReceived(.remove(gid)), let .removeTapped(gid):
                return perform({ try await aria2Client.remove(gid: gid) }, then: .removed(gid: gid))

            case let .statusesReceived(statuses):
                var effects: [Effect<Action>] = []

                for status in statuses {
                    switch status.status {
                    case .complete, .error, .removed:
                        effects.append(finished(status, state: &state))
                    default:
                        if state.downloads[id: status.gid]?.status != status {
                            state.$downloads.withLock { $0[id: status.gid]?.updateStatus(status) }
                        }
                    }
                }

                return .merge(effects)

            case let .started(download):
                let isFirst = state.downloads.isEmpty

                state.$downloads.withLock { _ = $0.append(download) }
                state.$hasDownloads.withLock { $0 = true }

                return .merge(
                    .run { _ in
                        await notifications.post(.downloading(download.data, gid: download.gid))
                    },
                    isFirst ? polling(state.$downloads) : .none
                )

            case let .pauseTapped(gid):
                return perform({ try await aria2Client.pause(gid: gid) }, then: .paused(gid: gid))

            case let .unpauseTapped(gid):
                return perform({ try await aria2Client.unpause(gid: gid) }, then: .unpaused(gid: gid))

            case let .paused(gid):
                state.$downloads.withLock { $0[id: gid]?.pause() }

                return .none

            case let .unpaused(gid):
                state.$downloads.withLock { $0[id: gid]?.unpause() }

                return .none

            case let .removed(gid):
                guard let download = remove(gid, state: &state) else { return .none }

                return .run { _ in
                    download.folder.stopAccessingSecurityScopedResource()
                    await notifications.post(.canceled(download))

                    try? await aria2Client.removeDownloadResult(gid: gid)
                }
            }
        }
    }

    private func polling(_ downloads: Shared<IdentifiedArrayOf<Download>>) -> Effect<Action> {
        .run { send in
            for await _ in clock.timer(interval: .seconds(1)) {
                guard !downloads.wrappedValue.isEmpty else { return }

                if let statuses = try? await aria2Client.statuses() {
                    await send(.statusesReceived(statuses))
                }
            }
        }
        .cancellable(id: CancelID.polling, cancelInFlight: true)
    }

    private func perform(_ operation: @escaping @Sendable () async throws -> Void, then action: Action) -> Effect<Action> {
        .run { send in
            guard (try? await operation()) != nil else { return }

            await send(action)
        }
    }

    private func download(_ data: DownloadData) -> Effect<Action> {
        if data.episode == nil, let firstEpisode = data.season?.episodes.first {
            return download(data.withEpisode(firstEpisode))
        }

        guard let target = data.target else {
            return .run { _ in
                await notifications.post(.failed(data))
            }
        }

        return .run { send in
            let movie: MovieVideo

            do {
                movie = try await movieDetailsClient.getMovieVideo(voiceActing: data.acting, season: target.season, episode: target.episode, favs: data.details.favs)
            } catch {
                await notifications.post(.failed(data, reason: error.localizedDescription))

                return
            }

            guard !movie.needPremium else {
                await notifications.post(.needPremium(data))

                return
            }

            await selectionHistory.remember(acting: data.acting, season: target.season, episode: target.episode, subtitles: data.subtitles?.languageCode)

            guard let urls = movie.getClosestTo(quality: data.quality) else { return }

            _ = target.folder.startAccessingSecurityScopedResource()

            if let subtitles = data.subtitles,
               let movieSubtitles = movie.subtitles.first(where: { $0.name == subtitles.name }),
               let subtitlesURL = URL(string: movieSubtitles.link)
            {
                _ = try? await aria2Client.addUri(uris: [subtitlesURL], directory: target.directory, fileName: target.subtitlesFileName(movieSubtitles, url: subtitlesURL))
            }

            do {
                let gid = try await aria2Client.addUri(uris: urls, directory: target.directory, fileName: target.fileName)

                await send(.started(Download(gid: gid, data: data, folder: target.folder, fileURL: target.fileURL)))
            } catch {
                target.folder.stopAccessingSecurityScopedResource()

                await notifications.post(.failed(data, reason: (error as? Aria2Error)?.code.description))
            }
        }
    }

    private func finished(_ status: StatusResult, state: inout State) -> Effect<Action> {
        let download = remove(status.gid, state: &state)

        var effects: [Effect<Action>] = [
            .run { _ in
                download?.folder.stopAccessingSecurityScopedResource()

                try? await aria2Client.removeDownloadResult(gid: status.gid)
            },
        ]

        guard let download else { return .merge(effects) }

        switch status.status {
        case .complete:
            effects.append(.run { _ in await notifications.post(.succeeded(download)) })

            if download.data.all, let episode = download.data.episode, let nextEpisode = download.data.season?.episodes.element(after: episode) {
                effects.append(self.download(download.data.withEpisode(nextEpisode)))
            }
        case .error:
            let errorCode = status.errorCode.flatMap(Aria2ErrorCode.init(rawValue:)) ?? .unknownError

            effects.append(.run { _ in await notifications.post(.failed(download.data, reason: errorCode.description)) })
        default:
            break
        }

        return .merge(effects)
    }

    private func remove(_ gid: String, state: inout State) -> Download? {
        guard let download = state.downloads[id: gid] else { return nil }

        state.$downloads.withLock { _ = $0.remove(id: gid) }

        let hasDownloads = !state.downloads.isEmpty
        state.$hasDownloads.withLock { $0 = hasDownloads }

        return download
    }
}

extension SharedReaderKey where Self == InMemoryKey<IdentifiedArrayOf<Download>>.Default {
    static var downloads: Self {
        Self[.inMemory("downloads"), default: []]
    }
}

extension SharedReaderKey where Self == InMemoryKey<Bool>.Default {
    static var hasDownloads: Self {
        Self[.inMemory("hasDownloads"), default: false]
    }

    static var isDownloaderRunning: Self {
        Self[.inMemory("isDownloaderRunning"), default: false]
    }
}

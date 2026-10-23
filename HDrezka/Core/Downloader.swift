import Defaults
import Dependencies
import SQLiteData
import SwiftUI
import UserNotifications

@Observable
@MainActor
class Downloader {
    @ObservationIgnored static let shared = Downloader()

    @ObservationIgnored private var pollingTask: Task<Void, Never>?

    @ObservationIgnored @Dependency(\.saveWatchingStateUseCase) private var saveWatchingStateUseCase
    @ObservationIgnored @Dependency(\.getMovieVideoUseCase) private var getMovieVideoUseCase
    @ObservationIgnored @Dependency(\.callUseCase) private var callUseCase
    @ObservationIgnored @Dependency(\.multicallUseCase) private var multicallUseCase

    @ObservationIgnored @Dependency(\.defaultDatabase) private var database

    @ObservationIgnored private let process: Process

    var isRunning: Bool = false

    var downloads: [Download] = [] {
        didSet {
            if hasDownloads == downloads.isEmpty {
                hasDownloads = !downloads.isEmpty
            }
        }
    }

    private(set) var hasDownloads: Bool = false

    init() {
        let open = UNNotificationAction(identifier: "open", title: String(localized: "key.open"))
        let openCategory = UNNotificationCategory(identifier: "open", actions: [open], intentIdentifiers: [])

        let cancel = UNNotificationAction(identifier: "cancel", title: String(localized: "key.cancel"))
        let cancelCategory = UNNotificationCategory(identifier: "cancel", actions: [cancel], intentIdentifiers: [])

        let retry = UNNotificationAction(identifier: "retry", title: String(localized: "key.retry"))
        let retryCategory = UNNotificationCategory(identifier: "retry", actions: [retry], intentIdentifiers: [])

        let needPremium = UNNotificationAction(identifier: "need_premium", title: String(localized: "key.buy"))
        let needPremiumCategory = UNNotificationCategory(identifier: "need_premium", actions: [needPremium], intentIdentifiers: [])

        UNUserNotificationCenter.current().setNotificationCategories([openCategory, cancelCategory, retryCategory, needPremiumCategory])

        #if arch(arm64)
            guard let aria2URL = Bundle.main.url(forResource: "aria2c-arm64", withExtension: nil) else {
                fatalError("aria2c binary not found in bundle")
            }
        #elseif arch(x86_64)
            guard let aria2URL = Bundle.main.url(forResource: "aria2c-x86_64", withExtension: nil) else {
                fatalError("aria2c binary not found in bundle")
            }
        #else
            fatalError("Failed to start aria2 process: unknown architecture")
        #endif

        process = Process()
        process.executableURL = aria2URL
        process.arguments = [
            "--enable-rpc=true",
            "--rpc-listen-port=6800",
            "--rpc-secret=\(Const.token)",
            "--min-split-size=1M",
            "--max-connection-per-server=16",
            "--split=16",
            "--max-concurrent-downloads=\(Defaults[.maxConcurrentDownloads])",
            "--allow-overwrite=true",
            "--stop-with-process=\(ProcessInfo.processInfo.processIdentifier)",
            "--quiet=true",
            "--no-conf",
            "--user-agent=\(Const.userAgent)",
        ]

        process.terminationHandler = { [weak self] _ in
            guard let self else { return }

            Task { @MainActor [weak self] in
                guard let self else { return }

                self.pollingTask?.cancel()

                withAnimation(.easeInOut) {
                    self.isRunning = false
                }
            }
        }

        do {
            try process.run()

            withAnimation(.easeInOut) {
                self.isRunning = true
            }
        } catch {
            fatalError("Failed to start aria2 process: \(error)")
        }

        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))

                await self?.poll()
            }
        }
    }

    private func poll() async {
        guard let response: Aria2Response<GlobalStatusResult> = try? await callUseCase(
            data: Aria2Request(
                method: .getGlobalStat,
                params: EmptyTokenParams(
                    token: Const.token
                )
            )
        ),
            let result = response.result,
            result.numActive > 0 || result.numWaiting > 0 || result.numStopped > 0
        else {
            return
        }

        let keys = [
            "gid",
            "status",
            "totalLength",
            "completedLength",
            "downloadSpeed",
            "errorCode",
        ]

        var data: [Aria2Request<OffsetParams>] = []

        if result.numActive > 0 {
            data.append(
                Aria2Request(
                    method: .tellActive,
                    params: OffsetParams(
                        token: Const.token,
                        keys: keys
                    )
                )
            )
        }

        if result.numWaiting > 0 {
            data.append(
                Aria2Request(
                    method: .tellWaiting,
                    params: OffsetParams(
                        token: Const.token,
                        offset: 0,
                        num: result.numWaiting,
                        keys: keys
                    )
                )
            )
        }

        if result.numStopped > 0 {
            data.append(
                Aria2Request(
                    method: .tellStopped,
                    params: OffsetParams(
                        token: Const.token,
                        offset: 0,
                        num: result.numStopped,
                        keys: keys
                    )
                )
            )
        }

        guard let responses: [Aria2Response<[StatusResult]>] = try? await multicallUseCase(data: data) else { return }

        for response in responses {
            guard let statuses = response.result else { continue }

            for status in statuses {
                if status.status == .complete || status.status == .removed || status.status == .error {
                    if status.status == .complete,
                       let download = downloads.first(where: { $0.gid == status.gid })
                    {
                        notificate(download.data.notificationId, String(localized: "key.download.success"), String(localized: "key.download.success.notification-\(download.data.name)"), "open", ["url": download.fileURL.absoluteString])

                        if download.data.all, let episode = download.data.episode, let nextEpisode = download.data.season?.episodes.element(after: episode) {
                            self.download(download.data.newEpisede(nextEpisode))
                        }
                    }

                    if status.status == .error,
                       let download = downloads.first(where: { $0.gid == status.gid })
                    {
                        let errorCode = status.errorCode.flatMap(Aria2ErrorCode.init(rawValue:)) ?? .unknownError

                        if let retryData = download.data.retryData {
                            notificate(download.data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(download.data.name)-\(errorCode.description)"), "retry", ["data": retryData])
                        } else {
                            notificate(download.data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(download.data.name)-\(errorCode.description)"))
                        }
                    }

                    removeDownloadResult(status.gid)

                    downloads.removeAll(where: { $0.gid == status.gid })
                } else if let index = downloads.firstIndex(where: { $0.gid == status.gid }), downloads[index].status != status {
                    downloads[index].updateStatus(status)
                }
            }
        }
    }

    nonisolated private func notificate(_ id: String, _ title: String, _ subtitle: String? = nil, _ category: String? = nil, _ userInfo: [String: any Sendable] = [:]) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                let content = UNMutableNotificationContent()
                content.title = title
                if let subtitle, !subtitle.isEmpty {
                    content.subtitle = subtitle
                }
                content.sound = UNNotificationSound.default
                if let category, !category.isEmpty {
                    content.categoryIdentifier = category
                }
                content.userInfo = userInfo

                let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)

                UNUserNotificationCenter.current().add(request)
            } else if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    if granted {
                        self.notificate(id, title, subtitle, category, userInfo)
                    }
                }
            }
        }
    }

    func download(_ data: DownloadData) {
        guard let retryData = data.retryData else {
            notificate(UUID().uuidString, String(localized: "key.download.failed"))

            return
        }

        let name = data.details.nameRussian

        let actingName = if !data.acting.name.isEmpty {
            " [\(data.acting.name)]"
        } else {
            ""
        }

        let qualityName = if !data.quality.isEmpty {
            " [\(data.quality)]"
        } else {
            ""
        }

        if let season = data.season, let episode = data.episode {
            let (seasonName, episodeName) = (
                String(localized: "key.season-\(season.name.contains(/^\d/) ? season.name : season.seasonId)"),
                String(localized: "key.episode-\(episode.name.contains(/^\d/) ? episode.name : episode.episodeId)")
            )

            let (movieFolder, seasonFolder, movieFile) = (
                name.count > 255 - actingName.count - qualityName.count ? "\(name.prefix(255 - actingName.count - qualityName.count - 4))... \(qualityName)\(actingName)" : "\(name)\(qualityName)\(actingName)",
                seasonName.count > 255 ? "\(seasonName.prefix(255 - 3))..." : "\(seasonName)",
                episodeName.count > 255 - 4 ? "\(episodeName.prefix(255 - 8))... .mp4" : "\(episodeName).mp4"
            )

            guard let movieDestination = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?
                .appending(path: "HDrezka", directoryHint: .isDirectory)
                .appending(path: movieFolder.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"), directoryHint: .isDirectory)
                .appending(path: seasonFolder.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"), directoryHint: .isDirectory)
            else {
                notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)"), "retry", ["data": retryData])

                return
            }

            Task {
                await start(data, retryData: retryData, season: season, episode: episode, destination: movieDestination, file: movieFile)
            }
        } else if let season = data.season, let episode = season.episodes.first {
            download(data.newEpisede(episode))
        } else {
            let file = name.count > 255 - 4 - actingName.count - qualityName.count ? "\(name.prefix(255 - 8 - actingName.count - qualityName.count))... \(qualityName)\(actingName).mp4" : "\(name)\(qualityName)\(actingName).mp4"

            guard let movieDestination = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?
                .appending(path: "HDrezka", directoryHint: .isDirectory)
            else {
                notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)"), "retry", ["data": retryData])

                return
            }

            Task {
                await start(data, retryData: retryData, season: nil, episode: nil, destination: movieDestination, file: file)
            }
        }
    }

    private func start(_ data: DownloadData, retryData: Data, season: MovieSeason?, episode: MovieEpisode?, destination: URL, file: String) async {
        let movie: MovieVideo

        do {
            movie = try await getMovieVideoUseCase(voiceActing: data.acting, season: season, episode: episode, favs: data.details.favs)
        } catch {
            notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])

            return
        }

        guard !movie.needPremium else {
            notificate(data.notificationId, String(localized: "key.download.needPremium"), String(localized: "key.download.needPremium.notification-\(data.name)"), "need_premium")

            return
        }

        if Defaults[.isLoggedIn] {
            Task {
                _ = try? await saveWatchingStateUseCase(voiceActing: data.acting, season: season, episode: episode)
            }
        }

        let voiceId = data.acting.voiceId
        let translatorId = data.acting.translatorId
        let seasonId = season?.seasonId
        let episodeId = episode?.episodeId
        let subtitles = data.subtitles?.lang.replacingOccurrences(of: "ua", with: "uk")

        Task.detached(priority: .utility) { [database] in
            try? await database.write { db in
                try SelectPosition
                    .upsert {
                        SelectPosition.Draft(
                            id: voiceId,
                            acting: translatorId,
                            season: seasonId,
                            episode: episodeId,
                            subtitles: subtitles
                        )
                    }
                    .execute(db)
            }
        }

        guard let movieUrls = movie.getClosestTo(quality: data.quality) else { return }

        let out = file.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":")

        if let subtitles = data.subtitles,
           let sub = movie.subtitles.first(where: { $0.name == subtitles.name }),
           let subtitlesUrl = URL(string: sub.link)
        {
            Task {
                let _: Aria2Response<String>? = try? await callUseCase(
                    data: Aria2Request(
                        method: .addUri,
                        params: AddUriParams(
                            token: Const.token,
                            uris: [subtitlesUrl.absoluteString],
                            options: [
                                "dir": destination.path(percentEncoded: false),
                                "out": out.replacingOccurrences(of: ".mp4", with: " [\(sub.name)].\(subtitlesUrl.pathExtension)"),
                            ]
                        )
                    )
                )
            }
        }

        guard let response: Aria2Response<String> = try? await callUseCase(
            data: Aria2Request(
                method: .addUri,
                params: AddUriParams(
                    token: Const.token,
                    uris: movieUrls.map(\.absoluteString),
                    options: [
                        "dir": destination.path(percentEncoded: false),
                        "out": out,
                    ]
                )
            )
        ) else {
            return
        }

        if let gid = response.result {
            downloads.append(
                .init(
                    gid: gid,
                    data: data,
                    fileURL: destination.appending(path: out, directoryHint: .notDirectory)
                )
            )

            notificate(data.notificationId, String(localized: "key.download.downloading"), String(localized: "key.download.downloading.notification-\(data.name)"), "cancel", ["gid": gid])
        } else if let error = response.error {
            notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.code.description)"), "retry", ["data": retryData])
        } else {
            notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)"), "retry", ["data": retryData])
        }
    }

    func maxConcurrentDownloadsChange() {
        Task {
            let _: Aria2Response<String>? = try? await callUseCase(
                data: Aria2Request(
                    method: .changeGlobalOption,
                    params: OptionsParams(
                        token: Const.token,
                        options: [
                            "max-concurrent-downloads": Defaults[.maxConcurrentDownloads],
                        ]
                    )
                )
            )
        }
    }

    func remove(_ gid: String) {
        Task {
            guard let response: Aria2Response<String> = try? await callUseCase(
                data: Aria2Request(
                    method: .remove,
                    params: GidParams(
                        token: Const.token,
                        gid: gid
                    )
                )
            ),
                let gid = response.result
            else {
                return
            }

            if let download = downloads.first(where: { $0.gid == gid }) {
                if let retryData = download.data.retryData {
                    notificate(download.data.notificationId, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(download.data.name)"), "retry", ["data": retryData])
                } else {
                    notificate(download.data.notificationId, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(download.data.name)"))
                }
            }

            downloads.removeAll(where: { $0.gid == gid })

            removeDownloadResult(gid)
        }
    }

    func pause(_ gid: String) {
        Task {
            guard let response: Aria2Response<String> = try? await callUseCase(
                data: Aria2Request(
                    method: .pause,
                    params: GidParams(
                        token: Const.token,
                        gid: gid
                    )
                )
            ),
                let gid = response.result,
                let index = downloads.firstIndex(where: { $0.gid == gid })
            else {
                return
            }

            downloads[index].pause()
        }
    }

    func unpause(_ gid: String) {
        Task {
            guard let response: Aria2Response<String> = try? await callUseCase(
                data: Aria2Request(
                    method: .unpause,
                    params: GidParams(
                        token: Const.token,
                        gid: gid
                    )
                )
            ),
                let gid = response.result,
                let index = downloads.firstIndex(where: { $0.gid == gid })
            else {
                return
            }

            downloads[index].unpause()
        }
    }

    private func removeDownloadResult(_ gid: String) {
        Task {
            let _: Aria2Response<String>? = try? await callUseCase(
                data: Aria2Request(
                    method: .removeDownloadResult,
                    params: GidParams(
                        token: Const.token,
                        gid: gid
                    )
                )
            )
        }
    }

    func terminate() {
        process.terminate()
    }
}

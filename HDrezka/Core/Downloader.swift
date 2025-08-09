import Combine
import Defaults
import FactoryKit
import SwiftData
import SwiftUI
import UserNotifications

@Observable
class Downloader {
    @ObservationIgnored static let shared = Downloader()

    @ObservationIgnored private var modelContext: ModelContext?

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    @ObservationIgnored @LazyInjected(\.saveWatchingStateUseCase) private var saveWatchingStateUseCase
    @ObservationIgnored @LazyInjected(\.getMovieVideoUseCase) private var getMovieVideoUseCase
    @ObservationIgnored @LazyInjected(\.callUseCase) private var callUseCase
    @ObservationIgnored @LazyInjected(\.multicallUseCase) private var multicallUseCase

    @ObservationIgnored private let fileManager = FileManager.default

    @ObservationIgnored private let process: Process

    var isRunning: Bool = false

    var downloads: [Download] = []

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

        guard let aria2URL = Bundle.main.url(forResource: "aria2c", withExtension: nil) else {
            fatalError("aria2c binary not found in bundle")
        }

        process = Process()
        process.executableURL = aria2URL
        process.arguments = [
            "--enable-rpc=true",
            "--rpc-listen-port=6800",
            "--rpc-secret=\(Const.token)",
            "--max-concurrent-downloads=\(Defaults[.maxConcurrentDownloads])",
            "--stop-with-process=\(ProcessInfo.processInfo.processIdentifier)",
            "--quiet=true",
            "--allow-overwrite=true",
            "--user-agent=\(Const.userAgent)",
        ]

        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                self.subscriptions.flush()

                withAnimation(.easeInOut) {
                    self.isRunning = false
                }
            }
        }

        do {
            try process.run()

            process.publisher(for: \.isRunning)
                .receive(on: DispatchQueue.main)
                .sink { isRunning in
                    withAnimation(.easeInOut) {
                        self.isRunning = isRunning
                    }
                }
                .store(in: &subscriptions)
        } catch {
            fatalError("Failed to start aria2 process: \(error)")
        }

        Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
            .flatMap { _ in
                self.callUseCase(data:
                    Aria2Request(
                        method: .getGlobalStat,
                        params: EmptyTokenParams(
                            token: Const.token,
                        ),
                    ))
                    .catch { _ in Empty<Aria2Response<GlobalStatusResult>, Error>() }
            }
            .flatMap { (response: Aria2Response<GlobalStatusResult>) in
                guard let result = response.result,
                      result.numActive > 0 || result.numWaiting > 0 || result.numStopped > 0
                else {
                    return Empty<[Aria2Response<[StatusResult]>], Error>().eraseToAnyPublisher()
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
                                keys: keys,
                            ),
                        ),
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
                                keys: keys,
                            ),
                        ),
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
                                keys: keys,
                            ),
                        ),
                    )
                }

                return self.multicallUseCase(data: data)
                    .catch { _ in Empty<[Aria2Response<[StatusResult]>], Error>() }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { (responses: [Aria2Response<[StatusResult]>]) in
                for response in responses {
                    if let statuses = response.result {
                        for status in statuses {
                            if status.status == .complete || status.status == .removed || status.status == .error {
                                if status.status == .complete,
                                   let download = self.downloads.first(where: { download in
                                       download.gid == status.gid
                                   })
                                {
                                    self.notificate(download.data.notificationId, String(localized: "key.download.success"), String(localized: "key.download.success.notification-\(download.data.name)"), "open", ["url": download.fileURL.absoluteString])

                                    if download.data.all, let episode = download.data.episode, let nextEpisode = download.data.season?.episodes.element(after: episode) {
                                        self.download(download.data.newEpisede(nextEpisode))
                                    }
                                }

                                if status.status == .error,
                                   let download = self.downloads.first(where: { download in
                                       download.gid == status.gid
                                   })
                                {
                                    if let errorCode = status.errorCode,
                                       let aria2ErrorCode = Aria2ErrorCode(rawValue: errorCode)
                                    {
                                        if let retryData = download.data.retryData {
                                            self.notificate(download.data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(download.data.name)-\(aria2ErrorCode.description)"), "retry", ["data": retryData])
                                        } else {
                                            self.notificate(download.data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(download.data.name)-\(aria2ErrorCode.description)"))
                                        }
                                    } else {
                                        if let retryData = download.data.retryData {
                                            self.notificate(download.data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(download.data.name)-\(Aria2ErrorCode.unknownError.description)"), "retry", ["data": retryData])
                                        } else {
                                            self.notificate(download.data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(download.data.name)-\(Aria2ErrorCode.unknownError.description)"))
                                        }
                                    }
                                }

                                self.callUseCase(
                                    data: Aria2Request(
                                        method: .removeDownloadResult,
                                        params: GidParams(
                                            token: Const.token,
                                            gid: status.gid,
                                        ),
                                    ),
                                )
                                .sink { _ in } receiveValue: { (_: Aria2Response<String>) in }
                                .store(in: &self.subscriptions)

                                self.downloads.removeAll(where: { $0.gid == status.gid })
                            } else if let index = self.downloads.firstIndex(where: { download in
                                download.gid == status.gid
                            }) {
                                self.downloads[index].updateStatus(status)
                            }
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func setModelContext(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func notificate(_ id: String, _ title: String, _ subtitle: String? = nil, _ category: String? = nil, _ userInfo: [AnyHashable: Any] = [:]) {
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
        if let retryData = data.retryData {
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
                    String(localized: "key.episode-\(episode.name.contains(/^\d/) ? episode.name : episode.episodeId)"),
                )

                let (movieFolder, seasonFolder, movieFile) = (
                    name.count > 255 - actingName.count - qualityName.count ? "\(name.prefix(255 - actingName.count - qualityName.count - 4))... \(qualityName)\(actingName)" : "\(name)\(qualityName)\(actingName)",
                    seasonName.count > 255 ? "\(seasonName.prefix(255 - 3))..." : "\(seasonName)",
                    episodeName.count > 255 - 4 ? "\(episodeName.prefix(255 - 8))... .mp4" : "\(episodeName).mp4",
                )

                if let movieDestination = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first?
                    .appending(path: "HDrezka", directoryHint: .isDirectory)
                    .appending(path: movieFolder.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"), directoryHint: .isDirectory)
                    .appending(path: seasonFolder.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"), directoryHint: .isDirectory)
                {
                    getMovieVideoUseCase(voiceActing: data.acting, season: season, episode: episode, favs: data.details.favs)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            guard case let .failure(error) = completion else { return }

                            self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                        } receiveValue: { movie in
                            if movie.needPremium {
                                self.notificate(data.notificationId, String(localized: "key.download.needPremium"), String(localized: "key.download.needPremium.notification-\(data.name)"), "need_premium")
                            } else {
                                if Defaults[.isLoggedIn] {
                                    self.saveWatchingStateUseCase(voiceActing: data.acting, season: season, episode: episode, position: 0, total: 0)
                                        .sink { _ in } receiveValue: { _ in }
                                        .store(in: &self.subscriptions)
                                }

                                if let modelContext = self.modelContext {
                                    if let position = try? modelContext.fetch(FetchDescriptor<SelectPosition>(predicate: nil)).first(where: { position in
                                        position.id == data.acting.voiceId
                                    }) {
                                        position.acting = data.acting.translatorId
                                        position.season = season.seasonId
                                        position.episode = episode.episodeId
                                        position.subtitles = data.subtitles?.lang.replacingOccurrences(of: "ua", with: "uk")
                                    } else {
                                        let position = SelectPosition(
                                            id: data.acting.voiceId,
                                            acting: data.acting.translatorId,
                                            season: season.seasonId,
                                            episode: episode.episodeId,
                                            subtitles: data.subtitles?.lang.replacingOccurrences(of: "ua", with: "uk"),
                                        )

                                        modelContext.insert(position)
                                    }
                                }

                                if let movieUrl = movie.getClosestTo(quality: data.quality) {
                                    self.callUseCase(
                                        data: Aria2Request(
                                            method: .addUri,
                                            params: AddUriParams(
                                                token: Const.token,
                                                uris: [movieUrl.absoluteString],
                                                options: [
                                                    "dir": movieDestination.path(percentEncoded: false),
                                                    "out": movieFile.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"),
                                                ],
                                            ),
                                        ),
                                    )
                                    .receive(on: DispatchQueue.main)
                                    .sink { _ in } receiveValue: { (response: Aria2Response<String>) in
                                        if let gid = response.result {
                                            self.downloads.append(
                                                .init(
                                                    gid: gid,
                                                    data: data,
                                                    fileURL: movieDestination.appending(path: movieFile.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"), directoryHint: .notDirectory),
                                                ),
                                            )

                                            self.notificate(data.notificationId, String(localized: "key.download.downloading"), String(localized: "key.download.downloading.notification-\(data.name)"), "cancel", ["gid": gid])
                                        } else if let error = response.error {
                                            self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.code.description)"), "retry", ["data": retryData])
                                        } else {
                                            self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized:
                                                "key.download.failed.notification-\(data.name)"), "retry", ["data": retryData])
                                        }
                                    }
                                    .store(in: &self.subscriptions)

                                    if let subtitles = data.subtitles,
                                       let sub = movie.subtitles.first(where: { $0.name == subtitles.name }),
                                       let subtitlesUrl = URL(string: sub.link)
                                    {
                                        self.callUseCase(
                                            data: Aria2Request(
                                                method: .addUri,
                                                params: AddUriParams(
                                                    token: Const.token,
                                                    uris: [subtitlesUrl.absoluteString],
                                                    options: [
                                                        "dir": movieDestination.path(percentEncoded: false),
                                                        "out": movieFile.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":").replacingOccurrences(of: ".mp4", with: " [\(sub.name)].\(subtitlesUrl.pathExtension)"),
                                                    ],
                                                ),
                                            ),
                                        )
                                        .sink { _ in } receiveValue: { (_: Aria2Response<String>) in }
                                        .store(in: &self.subscriptions)
                                    }
                                }
                            }
                        }
                        .store(in: &subscriptions)
                } else {
                    notificate(data.notificationId, String(localized: "key.download.failed"), String(localized:
                        "key.download.failed.notification-\(data.name)"), "retry", ["data": retryData])
                }
            } else if let season = data.season, let episode = season.episodes.first {
                download(data.newEpisede(episode))
            } else {
                let file = name.count > 255 - 4 - actingName.count - qualityName.count ? "\(name.prefix(255 - 8 - actingName.count - qualityName.count))... \(qualityName)\(actingName).mp4" : "\(name)\(qualityName)\(actingName).mp4"

                if let movieDestination = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first?
                    .appending(path: "HDrezka", directoryHint: .isDirectory)
                {
                    getMovieVideoUseCase(voiceActing: data.acting, season: nil, episode: nil, favs: data.details.favs)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            guard case let .failure(error) = completion else { return }

                            self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized:
                                "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                        } receiveValue: { movie in
                            if movie.needPremium {
                                self.notificate(data.notificationId, String(localized: "key.download.needPremium"), String(localized: "key.download.needPremium.notification-\(data.name)"), "need_premium")
                            } else {
                                if Defaults[.isLoggedIn] {
                                    self.saveWatchingStateUseCase(voiceActing: data.acting, season: nil, episode: nil, position: 0, total: 0)
                                        .sink { _ in } receiveValue: { _ in }
                                        .store(in: &self.subscriptions)
                                }

                                if let modelContext = self.modelContext {
                                    if let position = try? modelContext.fetch(FetchDescriptor<SelectPosition>(predicate: nil)).first(where: { position in
                                        position.id == data.acting.voiceId
                                    }) {
                                        position.acting = data.acting.translatorId
                                        position.subtitles = data.subtitles?.lang.replacingOccurrences(of: "ua", with: "uk")
                                    } else {
                                        let position = SelectPosition(
                                            id: data.acting.voiceId,
                                            acting: data.acting.translatorId,
                                            subtitles: data.subtitles?.lang.replacingOccurrences(of: "ua", with: "uk"),
                                        )

                                        modelContext.insert(position)
                                    }
                                }

                                if let movieUrl = movie.getClosestTo(quality: data.quality) {
                                    self.callUseCase(
                                        data: Aria2Request(
                                            method: .addUri,
                                            params: AddUriParams(
                                                token: Const.token,
                                                uris: [movieUrl.absoluteString],
                                                options: [
                                                    "dir": movieDestination.path(percentEncoded: false),
                                                    "out": file.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"),
                                                ],
                                            ),
                                        ),
                                    )
                                    .receive(on: DispatchQueue.main)
                                    .sink { _ in } receiveValue: { (response: Aria2Response<String>) in
                                        if let gid = response.result {
                                            self.downloads.append(
                                                .init(
                                                    gid: gid,
                                                    data: data,
                                                    fileURL: movieDestination.appending(path: file.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"), directoryHint: .notDirectory),
                                                ),
                                            )

                                            self.notificate(data.notificationId, String(localized: "key.download.downloading"), String(localized: "key.download.downloading.notification-\(data.name)"), "cancel", ["gid": gid])
                                        } else if let error = response.error {
                                            self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized:
                                                "key.download.failed.notification-\(data.name)-\(error.code.description)"), "retry", ["data": retryData])
                                        } else {
                                            self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)"), "retry", ["data": retryData])
                                        }
                                    }
                                    .store(in: &self.subscriptions)

                                    if let subtitles = data.subtitles,
                                       let sub = movie.subtitles.first(where: { $0.name == subtitles.name }),
                                       let subtitlesUrl = URL(string: sub.link)
                                    {
                                        self.callUseCase(
                                            data: Aria2Request(
                                                method: .addUri,
                                                params: AddUriParams(
                                                    token: Const.token,
                                                    uris: [subtitlesUrl.absoluteString],
                                                    options: [
                                                        "dir": movieDestination.path(percentEncoded: false),
                                                        "out": file.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":").replacingOccurrences(of: ".mp4", with: " [\(sub.name)].\(subtitlesUrl.pathExtension)"),
                                                    ],
                                                ),
                                            ),
                                        )
                                        .sink { _ in } receiveValue: { (_: Aria2Response<String>) in }
                                        .store(in: &self.subscriptions)
                                    }
                                }
                            }
                        }
                        .store(in: &subscriptions)
                } else {
                    notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)"), "retry", ["data": retryData])
                }
            }
        } else {
            notificate(UUID().uuidString, String(localized: "key.download.failed"))
        }
    }

    func maxConcurrentDownloadsChange() {
        callUseCase(
            data: Aria2Request(
                method: .changeGlobalOption,
                params: OptionsParams(
                    token: Const.token,
                    options: [
                        "max-concurrent-downloads": Defaults[.maxConcurrentDownloads],
                    ],
                ),
            ),
        )
        .sink { _ in } receiveValue: { (_: Aria2Response<String>) in }
        .store(in: &subscriptions)
    }

    func remove(_ gid: String) {
        callUseCase(
            data: Aria2Request(
                method: .remove,
                params: GidParams(
                    token: Const.token,
                    gid: gid,
                ),
            ),
        )
        .receive(on: DispatchQueue.main)
        .sink { _ in } receiveValue: { (response: Aria2Response<String>) in
            if let gid = response.result {
                if let download = self.downloads.first(where: { download in
                    download.gid == gid
                }) {
                    if let retryData = download.data.retryData {
                        self.notificate(download.data.notificationId, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(download.data.name)"), "retry", ["data": retryData])
                    } else {
                        self.notificate(download.data.notificationId, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(download.data.name)"))
                    }
                }

                self.downloads.removeAll(where: { $0.gid == gid })

                self.callUseCase(
                    data: Aria2Request(
                        method: .removeDownloadResult,
                        params: GidParams(
                            token: Const.token,
                            gid: gid,
                        ),
                    ),
                )
                .sink { _ in } receiveValue: { (_: Aria2Response<String>) in }
                .store(in: &self.subscriptions)
            }
        }
        .store(in: &subscriptions)
    }

    func pause(_ gid: String) {
        callUseCase(
            data: Aria2Request(
                method: .pause,
                params: GidParams(
                    token: Const.token,
                    gid: gid,
                ),
            ),
        )
        .receive(on: DispatchQueue.main)
        .sink { _ in } receiveValue: { (response: Aria2Response<String>) in
            if let gid = response.result,
               let index = self.downloads.firstIndex(where: { download in
                   download.gid == gid
               })
            {
                self.downloads[index].pause()
            }
        }
        .store(in: &subscriptions)
    }

//    func pauseAll() {
//        callUseCase(
//            data: Aria2Request(
//                method: .pauseAll,
//                params: EmptyTokenParams(
//                    token: Const.token,
//                ),
//            ),
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { _ in } receiveValue: { (response: Aria2Response<String>) in
//            if response.result == "OK" {
//                for index in self.downloads.indices {
//                    self.downloads[index].pause()
//                }
//            }
//        }
//        .store(in: &subscriptions)
//    }

    func unpause(_ gid: String) {
        callUseCase(
            data: Aria2Request(
                method: .unpause,
                params: GidParams(
                    token: Const.token,
                    gid: gid,
                ),
            ),
        )
        .receive(on: DispatchQueue.main)
        .sink { _ in } receiveValue: { (response: Aria2Response<String>) in
            if let gid = response.result,
               let index = self.downloads.firstIndex(where: { download in
                   download.gid == gid
               })
            {
                self.downloads[index].unpause()
            }
        }
        .store(in: &subscriptions)
    }

//    func unpauseAll() {
//        callUseCase(
//            data: Aria2Request(
//                method: .unpauseAll,
//                params: EmptyTokenParams(
//                    token: Const.token,
//                ),
//            ),
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { _ in } receiveValue: { (response: Aria2Response<String>) in
//            if response.result == "OK" {
//                for index in self.downloads.indices {
//                    self.downloads[index].unpause()
//                }
//            }
//        }
//        .store(in: &subscriptions)
//    }

    func terminate() {
        process.terminate()
    }
}

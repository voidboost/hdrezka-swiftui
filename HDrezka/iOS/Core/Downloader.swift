import Combine
import Defaults
import FactoryKit
import MediaCore
import SwiftData
import UserNotifications

@Observable
class Downloader {
    @ObservationIgnored static let shared = Downloader()

    @ObservationIgnored private var modelContext: ModelContext?

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    @ObservationIgnored @LazyInjected(\.session) private var session
    @ObservationIgnored @LazyInjected(\.saveWatchingStateUseCase) private var saveWatchingStateUseCase
    @ObservationIgnored @LazyInjected(\.getMovieVideoUseCase) private var getMovieVideoUseCase

    var downloads: [Download] = []

//    @ObservationIgnored var backgroundCompletionHandler: (() -> Void)?

    init() {
        let open = UNNotificationAction(identifier: "open", title: String(localized: "key.open.gallery"))
        let openCategory = UNNotificationCategory(identifier: "open", actions: [open], intentIdentifiers: [])

        let cancel = UNNotificationAction(identifier: "cancel", title: String(localized: "key.cancel"))
        let cancelCategory = UNNotificationCategory(identifier: "cancel", actions: [cancel], intentIdentifiers: [])

        let retry = UNNotificationAction(identifier: "retry", title: String(localized: "key.retry"))
        let retryCategory = UNNotificationCategory(identifier: "retry", actions: [retry], intentIdentifiers: [])

        let needPremium = UNNotificationAction(identifier: "need_premium", title: String(localized: "key.buy"))
        let needPremiumCategory = UNNotificationCategory(identifier: "need_premium", actions: [needPremium], intentIdentifiers: [])

        UNUserNotificationCenter.current().setNotificationCategories([openCategory, cancelCategory, retryCategory, needPremiumCategory])
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

    private func saveToPhotos(_ url: URL, _ data: DownloadData, _ retryData: Data, _ completion: @escaping () -> Void = {}) {
        if Media.isAccessAllowed {
            if let album = try? Album.with(localizedTitle: "HDrezka") {
                do {
                    try Video.save(.init(url: url)) { result in
                        switch result {
                        case let .success(video):
                            album.add(video) { result in
                                switch result {
                                case .success:
                                    try? FileManager.default.removeItem(at: url)

                                    self.notificate(data.notificationId, String(localized: "key.download.success"), String(localized:
                                        "key.download.success.notification-\(data.name)"), "open", ["url": Const.photos.absoluteString])

                                    completion()
                                case let .failure(error):
                                    self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                                }
                            }
                        case let .failure(error):
                            self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                        }
                    }
                } catch {
                    notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                }
            } else {
                Album.create(title: "HDrezka") { result in
                    switch result {
                    case .success:
                        self.saveToPhotos(url, data, retryData, completion)
                    case let .failure(error):
                        self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                    }
                }
            }
        } else {
            Media.requestPermission { result in
                switch result {
                case .success:
                    self.saveToPhotos(url, data, retryData, completion)
                case let .failure(error):
                    self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
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

                if let movieDestination = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?
                    .appending(path: "HDrezka", directoryHint: .isDirectory)
                    .appending(path: movieFolder.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"), directoryHint: .isDirectory)
                    .appending(path: seasonFolder.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"), directoryHint: .isDirectory)
                    .appending(path: movieFile.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"), directoryHint: .notDirectory)
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
                                    } else {
                                        let position = SelectPosition(
                                            id: data.acting.voiceId,
                                            acting: data.acting.translatorId,
                                            season: season.seasonId,
                                            episode: episode.episodeId,
                                        )

                                        modelContext.insert(position)
                                    }
                                }

                                if let movieUrl = movie.getClosestTo(quality: data.quality) {
                                    self.notificate(data.notificationId, String(localized: "key.download.downloading"), String(localized: "key.download.downloading.notification-\(data.name)"), "cancel", ["id": data.notificationId])

                                    let request = self.session.download(movieUrl, method: .get, headers: [.userAgent(Const.userAgent)], to: { _, _ in (movieDestination, [.createIntermediateDirectories, .removePreviousFile]) })
                                        .validate(statusCode: 200 ..< 400)
                                        .responseURL(queue: .main) { response in
                                            self.downloads.removeAll(where: { $0.id == data.notificationId })

                                            if let error = response.error {
                                                if error.isExplicitlyCancelledError {
                                                    self.notificate(data.notificationId, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(data.name)"), "retry", ["data": retryData])
                                                } else {
                                                    self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                                                }
                                            } else if let destination = response.value {
                                                self.saveToPhotos(destination, data, retryData) {
                                                    if data.all, let nextEpisode = season.episodes.element(after: episode) {
                                                        self.download(data.newEpisede(nextEpisode))
                                                    }
                                                }
                                            }
                                        }

                                    request.downloadProgress.localizedDescription = data.name
                                    request.downloadProgress.kind = .file
                                    request.downloadProgress.fileOperationKind = .downloading

                                    self.downloads.append(
                                        .init(
                                            id: data.notificationId,
                                            data: data,
                                            request: request,
                                        ),
                                    )

                                    request.resume()
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

                if let movieDestination = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?
                    .appending(path: "HDrezka", directoryHint: .isDirectory)
                    .appending(path: file.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"), directoryHint: .notDirectory)
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
                                    } else {
                                        let position = SelectPosition(
                                            id: data.acting.voiceId,
                                            acting: data.acting.translatorId,
                                        )

                                        modelContext.insert(position)
                                    }
                                }

                                if let movieUrl = movie.getClosestTo(quality: data.quality) {
                                    self.notificate(data.notificationId, String(localized: "key.download.downloading"), String(localized: "key.download.downloading.notification-\(data.name)"), "cancel", ["id": data.notificationId])

                                    let request = self.session.download(movieUrl, method: .get, headers: [.userAgent(Const.userAgent)], to: { _, _ in (movieDestination, [.createIntermediateDirectories, .removePreviousFile]) })
                                        .validate(statusCode: 200 ..< 400)
                                        .responseURL(queue: .main) { response in
                                            self.downloads.removeAll(where: { $0.id == data.notificationId })

                                            if let error = response.error {
                                                if error.isExplicitlyCancelledError {
                                                    self.notificate(data.notificationId, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(data.name)"), "retry", ["data": retryData])
                                                } else {
                                                    self.notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                                                }
                                            } else if let destination = response.value {
                                                self.saveToPhotos(destination, data, retryData)
                                            }
                                        }

                                    request.downloadProgress.localizedDescription = data.name
                                    request.downloadProgress.kind = .file
                                    request.downloadProgress.fileOperationKind = .downloading

                                    self.downloads.append(
                                        .init(
                                            id: data.notificationId,
                                            data: data,
                                            request: request,
                                        ),
                                    )

                                    request.resume()
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
}

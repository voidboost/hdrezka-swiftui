import Combine
import CoreData
import Defaults
import FactoryKit
import UserNotifications

@Observable
class Downloader {
    @ObservationIgnored
    static let shared = Downloader()

    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []
    
    @ObservationIgnored
    @Injected(\.session)
    private var session
    @ObservationIgnored
    @Injected(\.saveWatchingStateUseCase)
    private var saveWatchingStateUseCase
    @ObservationIgnored
    @Injected(\.getMovieVideoUseCase)
    private var getMovieVideoUseCase

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
        if let retryData = try? JSONEncoder().encode(data) {
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
                let (s, e) = (
                    "Season \(season.name.contains(/^\d/) ? season.name : season.seasonId)",
                    "Episode \(episode.name.contains(/^\d/) ? episode.name : episode.episodeId)"
                )
                
                let (movieFolder, seasonFolder, movieFile) = (
                    name.count > 255 - actingName.count - qualityName.count ? "\(name.prefix(255 - actingName.count - qualityName.count - 4))... \(qualityName)\(actingName)" : "\(name)\(qualityName)\(actingName)",
                    s.count > 255 ? "\(s.prefix(255 - 3))..." : "\(s)",
                    e.count > 255 - 4 ? "\(e.prefix(255 - 8))... .mp4" : "\(e).mp4"
                )
                
                let id = "\(data.details.movieId)\(season.seasonId)\(episode.episodeId)\(data.acting.translatorId)\(data.quality)".base64Encoded
                
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
                            
                            self.notificate(id, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)-\(error.localizedDescription)"), "retry", ["data": retryData])
                        } receiveValue: { movie in
                            if movie.needPremium {
                                self.notificate(id, String(localized: "key.download.needPremium"), String(localized: "key.download.needPremium.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)"), "need_premium")
                            } else {
                                if Defaults[.isLoggedIn] {
                                    self.saveWatchingStateUseCase(voiceActing: data.acting, season: season, episode: episode, position: 0, total: 0)
                                        .sink { _ in } receiveValue: { _ in }
                                        .store(in: &self.subscriptions)
                                }
                                
                                if let position = try? PersistenceController.shared.viewContext.fetch(SelectPosition.fetch()).first(where: { position in
                                    position.id == data.acting.voiceId
                                }) {
                                    position.acting = data.acting.translatorId
                                    position.season = season.seasonId
                                    position.episode = episode.episodeId
                                    position.subtitles = data.subtitles?.lang.replacingOccurrences(of: "ua", with: "uk")
                                    
                                    position.managedObjectContext?.saveContext()
                                } else {
                                    let position = SelectPosition(context: PersistenceController.shared.viewContext)
                                    position.id = data.acting.voiceId
                                    position.acting = data.acting.translatorId
                                    position.season = season.seasonId
                                    position.episode = episode.episodeId
                                    position.subtitles = data.subtitles?.lang.replacingOccurrences(of: "ua", with: "uk")
                                        
                                    PersistenceController.shared.viewContext.saveContext()
                                }
                                
                                if let movieUrl = movie.getClosestTo(quality: data.quality) {
                                    self.notificate(id, String(localized: "key.download.downloading"), String(localized: "key.download.downloading.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)"), "cancel", ["id": id])
                                            
                                    let request = self.session.download(movieUrl, method: .get, headers: [.userAgent(Const.userAgent)], to: { _, _ in (movieDestination, [.createIntermediateDirectories, .removePreviousFile]) })
                                        .validate(statusCode: 200 ..< 400)
                                        .responseURL(queue: .main) { response in
                                            self.downloads.removeAll(where: { $0.id == id })
                                            
                                            if let error = response.error {
                                                if error.isExplicitlyCancelledError {
                                                    self.notificate(id, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)"), "retry", ["data": retryData])
                                                } else {
                                                    self.notificate(id, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)-\(error.localizedDescription)"), "retry", ["data": retryData])
                                                }
                                            } else if let destination = response.value {
                                                self.notificate(id, String(localized: "key.download.success"), String(localized: "key.download.success.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)"), "open", ["url": destination.absoluteString])
                                                    
                                                if data.all, let nextEpisode = season.episodes.element(after: episode) {
                                                    self.download(data.newEpisede(nextEpisode))
                                                }
                                            }
                                        }
                                           
                                    if let subtitles = data.subtitles,
                                       let sub = movie.subtitles.first(where: { $0.name == subtitles.name }),
                                       let subtitlesUrl = URL(string: sub.link)
                                    {
                                        let request = self.session.download(subtitlesUrl, method: .get, headers: [.userAgent(Const.userAgent)], to: { _, _ in (movieDestination.deletingLastPathComponent().appending(path: movieFile.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":").replacingOccurrences(of: ".mp4", with: " [\(sub.name)].\(subtitlesUrl.pathExtension)"), directoryHint: .notDirectory), [.createIntermediateDirectories, .removePreviousFile]) })
                                            .validate(statusCode: 200 ..< 400)
                                            
                                        request.resume()
                                    }
                                    
                                    request.downloadProgress.localizedDescription = "\(name) \(s) \(e)\(qualityName)\(actingName)"
                                    request.downloadProgress.kind = .file
                                    request.downloadProgress.fileOperationKind = .downloading
                                    
                                    self.downloads.append(
                                        .init(
                                            id: id,
                                            request: request
                                        )
                                    )

                                    request.resume()
                                }
                            }
                        }
                        .store(in: &subscriptions)
                } else {
                    notificate(id, String(localized: "key.download.failed"), String(localized:
                        "key.download.failed.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)"
                    ), "retry", ["data": retryData])
                }
            } else if let season = data.season, let episode = season.episodes.first {
                download(data.newEpisede(episode))
            } else {
                let file = name.count > 255 - 4 - actingName.count - qualityName.count ? "\(name.prefix(255 - 8 - actingName.count - qualityName.count))... \(qualityName)\(actingName).mp4" : "\(name)\(qualityName)\(actingName).mp4"
                
                let id = "\(data.details.movieId)\(data.acting.translatorId)\(data.quality)".base64Encoded
                
                if let movieDestination = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?
                    .appending(path: "HDrezka", directoryHint: .isDirectory)
                    .appending(path: file.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":"), directoryHint: .notDirectory)
                {
                    getMovieVideoUseCase(voiceActing: data.acting, season: nil, episode: nil, favs: data.details.favs)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            guard case let .failure(error) = completion else { return }
                            
                            self.notificate(id, String(localized: "key.download.failed"), String(localized:
                                "key.download.failed.notification-\(name)-\(qualityName)-\(actingName)-\(error.localizedDescription)"
                            ), "retry", ["data": retryData])
                        } receiveValue: { movie in
                            if movie.needPremium {
                                self.notificate(id, String(localized: "key.download.needPremium"), String(localized: "key.download.needPremium.notification-\(name)-\(qualityName)-\(actingName)"), "need_premium")
                            } else {
                                if Defaults[.isLoggedIn] {
                                    self.saveWatchingStateUseCase(voiceActing: data.acting, season: nil, episode: nil, position: 0, total: 0)
                                        .sink { _ in } receiveValue: { _ in }
                                        .store(in: &self.subscriptions)
                                }
                                
                                if let position = try? PersistenceController.shared.viewContext.fetch(SelectPosition.fetch()).first(where: { position in
                                    position.id == data.acting.voiceId
                                }) {
                                    position.acting = data.acting.translatorId
                                    position.subtitles = data.subtitles?.lang.replacingOccurrences(of: "ua", with: "uk")
                                    
                                    position.managedObjectContext?.saveContext()
                                } else {
                                    let position = SelectPosition(context: PersistenceController.shared.viewContext)
                                    position.id = data.acting.voiceId
                                    position.acting = data.acting.translatorId
                                    position.subtitles = data.subtitles?.lang.replacingOccurrences(of: "ua", with: "uk")
                                   
                                    PersistenceController.shared.viewContext.saveContext()
                                }
                                
                                if let movieUrl = movie.getClosestTo(quality: data.quality) {
                                    self.notificate(id, String(localized: "key.download.downloading"), String(localized: "key.download.downloading.notification-\(name)-\(qualityName)-\(actingName)"
                                    ), "cancel", ["id": id])
                                            
                                    let request = self.session.download(movieUrl, method: .get, headers: [.userAgent(Const.userAgent)], to: { _, _ in (movieDestination, [.createIntermediateDirectories, .removePreviousFile]) })
                                        .validate(statusCode: 200 ..< 400)
                                        .responseURL(queue: .main) { response in
                                            self.downloads.removeAll(where: { $0.id == id })

                                            if let error = response.error {
                                                if error.isExplicitlyCancelledError {
                                                    self.notificate(id, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(name)-\(qualityName)-\(actingName)"), "retry", ["data": retryData])
                                                } else {
                                                    self.notificate(id, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(name)-\(qualityName)-\(actingName)-\(error.localizedDescription)"), "retry", ["data": retryData])
                                                }
                                            } else if let destination = response.value {
                                                self.notificate(id, String(localized: "key.download.success"), String(localized:
                                                    "key.download.success.notification-\(name)-\(qualityName)-\(actingName)"), "open", ["url": destination.absoluteString])
                                            }
                                        }
                                    
                                    if let subtitles = data.subtitles,
                                       let sub = movie.subtitles.first(where: { $0.name == subtitles.name }),
                                       let subtitlesUrl = URL(string: sub.link)
                                    {
                                        let request = self.session.download(subtitlesUrl, method: .get, headers: [.userAgent(Const.userAgent)], to: { _, _ in (movieDestination.deletingLastPathComponent().appending(path: file.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":").replacingOccurrences(of: ".mp4", with: " [\(sub.name)].\(subtitlesUrl.pathExtension)"), directoryHint: .notDirectory), [.createIntermediateDirectories, .removePreviousFile]) })
                                            .validate(statusCode: 200 ..< 400)
                                            
                                        request.resume()
                                    }
                                    
                                    request.downloadProgress.localizedDescription = "\(name)\(qualityName)\(actingName)"
                                    request.downloadProgress.kind = .file
                                    request.downloadProgress.fileOperationKind = .downloading
                                    
                                    self.downloads.append(
                                        .init(
                                            id: id,
                                            request: request
                                        )
                                    )
                                    
                                    request.resume()
                                }
                            }
                        }
                        .store(in: &subscriptions)
                } else {
                    notificate(id, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(name)-\(qualityName)-\(actingName)"), "retry", ["data": retryData])
                }
            }
        } else {
            notificate(UUID().uuidString, String(localized: "key.download.failed"))
        }
    }
}

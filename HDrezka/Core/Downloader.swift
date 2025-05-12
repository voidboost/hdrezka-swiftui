import Combine
import Defaults
import Factory
import SwiftData
import UserNotifications

@Observable
class Downloader {
    @ObservationIgnored
    static let shared = Downloader()
    
    @ObservationIgnored
    private var modelContext: ModelContext?

    @ObservationIgnored
    private let notification = UNUserNotificationCenter.current()
    @ObservationIgnored
    private let fileManager = FileManager.default
    @ObservationIgnored
    private let encoder = JSONEncoder()

    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []
    
    @ObservationIgnored
    private let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: .main)

    @ObservationIgnored
    @Injected(\.account)
    private var account
    @ObservationIgnored
    @Injected(\.movieDetails)
    private var movieDetails

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

        notification.setNotificationCategories([openCategory, cancelCategory, retryCategory, needPremiumCategory])
    }
    
    func setModelContext(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    private func notificate(_ id: String, _ title: String, _ subtitle: String? = nil, _ category: String? = nil, _ userInfo: [AnyHashable: Any] = [:]) {
        notification.getNotificationSettings { settings in
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
                
                self.notification.add(request)
            } else if settings.authorizationStatus == .notDetermined {
                self.notification.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    if granted {
                        self.notificate(id, title, subtitle, category, userInfo)
                    }
                }
            }
        }
    }
    
    func download(_ data: DownloadData) {
        if let retryData = try? encoder.encode(data) {
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
                    movieDetails
                        .getMovieVideo(voiceActing: data.acting, season: season, episode: episode, favs: data.details.favs)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            guard case let .failure(error) = completion else { return }
                            
                            self.notificate(id, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)-\(error.localizedDescription)"), "retry", ["data": retryData])
                        } receiveValue: { movie in
                            if movie.needPremium {
                                self.notificate(id, String(localized: "key.download.needPremium"), String(localized: "key.download.needPremium.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)"), "need_premium")
                            } else {
                                if Defaults[.isLoggedIn] {
                                    self.account
                                        .saveWatchingState(voiceActing: data.acting, season: season, episode: episode, position: 0, total: 0)
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
                                            subtitles: data.subtitles?.lang.replacingOccurrences(of: "ua", with: "uk")
                                        )
                                        
                                        modelContext.insert(position)
                                    }
                                }
                                
                                if let string = movie.getClosestTo(quality: data.quality),
                                   let movieUrl = URL(string: string)
                                {
                                    self.notificate(id, String(localized: "key.download.downloading"), String(localized: "key.download.downloading.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)"), "cancel", ["id": id])
                                            
                                    let (urls, destinations): ([URL], [URL]) = if let subtitles = data.subtitles,
                                                                                  let sub = movie.subtitles.first(where: { $0.name == subtitles.name }),
                                                                                  let subtitlesUrl = URL(string: sub.link)
                                    {
                                        (
                                            [movieUrl, subtitlesUrl],
                                            [movieDestination, movieDestination.deletingLastPathComponent().appending(path: movieFile.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":").replacingOccurrences(of: ".mp4", with: " [\(sub.name)].\(subtitlesUrl.pathExtension)"), directoryHint: .notDirectory)]
                                        )
                                    } else {
                                        ([movieUrl], [movieDestination])
                                    }
                                    
                                    let task = self.session.downloadTask(with: urls[0]) { location, _, error in
                                        DispatchQueue.main.async {
                                            self.downloads.removeAll(where: { $0.id == id })
                                        }
                                        
                                        if let error {
                                            if (error as NSError).domain == NSURLErrorDomain, (error as NSError).code == NSURLErrorCancelled {
                                                self.notificate(id, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)"), "retry", ["data": retryData])
                                            } else {
                                                self.notificate(id, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)-\(error.localizedDescription)"), "retry", ["data": retryData])
                                            }
                                        } else if let location {
                                            do {
                                                try? self.fileManager.removeItem(at: destinations[0])

                                                try? self.fileManager.createDirectory(at: destinations[0].deletingLastPathComponent(), withIntermediateDirectories: true)

                                                try self.fileManager.moveItem(at: location, to: destinations[0])

                                                self.notificate(id, String(localized: "key.download.success"), String(localized: "key.download.success.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)"), "open", ["url": destinations[0].absoluteString])
                                                        
                                                if data.all, let nextEpisode = season.episodes.element(after: episode) {
                                                    self.download(data.newEpisede(nextEpisode))
                                                }
                                            } catch {
                                                self.notificate(id, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(name)-\(s)-\(e)-\(qualityName)-\(actingName)-\(error.localizedDescription)"), "retry", ["data": retryData])
                                            }
                                        }
                                    }
                                    
                                    task.priority = URLSessionTask.highPriority
                                    
                                    if urls.count > 1, destinations.count > 1 {
                                        let task = self.session.downloadTask(with: urls[1]) { location, _, _ in
                                            if let location {
                                                try? self.fileManager.removeItem(at: destinations[1])
                                                
                                                try? self.fileManager.createDirectory(at: destinations[1].deletingLastPathComponent(), withIntermediateDirectories: true)

                                                try? self.fileManager.moveItem(at: location, to: destinations[1])
                                            }
                                        }
                                        
                                        task.resume()
                                    }
                                    
                                    DispatchQueue.main.async {
                                        self.downloads.append(
                                            .init(
                                                id: id,
                                                name: "\(name) \(s) \(e)\(qualityName)\(actingName)",
                                                task: task
                                            )
                                        )
                                    }
                                    
                                    task.resume()
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
                    movieDetails
                        .getMovieVideo(voiceActing: data.acting, season: nil, episode: nil, favs: data.details.favs)
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
                                    self.account
                                        .saveWatchingState(voiceActing: data.acting, season: nil, episode: nil, position: 0, total: 0)
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
                                            subtitles: data.subtitles?.lang.replacingOccurrences(of: "ua", with: "uk")
                                        )
                                        
                                        modelContext.insert(position)
                                    }
                                }
                                
                                if let string = movie.getClosestTo(quality: data.quality),
                                   let movieUrl = URL(string: string)
                                {
                                    self.notificate(id, String(localized: "key.download.downloading"), String(localized: "key.download.downloading.notification-\(name)-\(qualityName)-\(actingName)"
                                    ), "cancel", ["id": id])
                                            
                                    let (urls, destinations): ([URL], [URL]) = if let subtitles = data.subtitles,
                                                                                  let sub = movie.subtitles.first(where: { $0.name == subtitles.name }),
                                                                                  let subtitlesUrl = URL(string: sub.link)
                                    {
                                        (
                                            [movieUrl, subtitlesUrl],
                                            [movieDestination, movieDestination.deletingLastPathComponent().appending(path: file.replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":").replacingOccurrences(of: ".mp4", with: " [\(sub.name)].\(subtitlesUrl.pathExtension)"), directoryHint: .notDirectory)]
                                        )
                                    } else {
                                        ([movieUrl], [movieDestination])
                                    }
                                    
                                    let task = self.session.downloadTask(with: urls[0]) { location, _, error in
                                        DispatchQueue.main.async {
                                            self.downloads.removeAll(where: { $0.id == id })
                                        }

                                        if let error {
                                            if (error as NSError).domain == NSURLErrorDomain, (error as NSError).code == NSURLErrorCancelled {
                                                self.notificate(id, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(name)-\(qualityName)-\(actingName)"), "retry", ["data": retryData])
                                            } else {
                                                self.notificate(id, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(name)-\(qualityName)-\(actingName)-\(error.localizedDescription)"), "retry", ["data": retryData])
                                            }
                                        } else if let location {
                                            do {
                                                try? self.fileManager.removeItem(at: destinations[0])
                                                
                                                try? self.fileManager.createDirectory(at: destinations[0].deletingLastPathComponent(), withIntermediateDirectories: true)

                                                try self.fileManager.moveItem(at: location, to: destinations[0])

                                                self.notificate(id, String(localized: "key.download.success"), String(localized:
                                                    "key.download.success.notification-\(name)-\(qualityName)-\(actingName)"), "open", ["url": movieDestination.absoluteString])
                                                        
                                            } catch {
                                                self.notificate(id, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(name)-\(qualityName)-\(actingName)-\(error.localizedDescription)"), "retry", ["data": retryData])
                                            }
                                        }
                                    }
                                    
                                    task.priority = URLSessionTask.highPriority

                                    if urls.count > 1, destinations.count > 1 {
                                        let task = self.session.downloadTask(with: urls[1]) { location, _, _ in
                                            if let location {
                                                try? self.fileManager.removeItem(at: destinations[1])

                                                try? self.fileManager.createDirectory(at: destinations[1].deletingLastPathComponent(), withIntermediateDirectories: true)
                                                
                                                try? self.fileManager.moveItem(at: location, to: destinations[1])
                                            }
                                        }
                                        
                                        task.resume()
                                    }
                                    
                                    DispatchQueue.main.async {
                                        self.downloads.append(
                                            .init(
                                                id: id,
                                                name: "\(name)\(qualityName)\(actingName)",
                                                task: task
                                            )
                                        )
                                    }
                                    
                                    task.resume()
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

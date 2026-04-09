import Combine
import Defaults
import FactoryKit
import Photos
import SwiftData
import UserNotifications

@Observable
class Downloader {
    @ObservationIgnored static let shared = Downloader()

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    @ObservationIgnored @LazyInjected(\.session) private var session
    @ObservationIgnored @LazyInjected(\.saveWatchingStateUseCase) private var saveWatchingStateUseCase
    @ObservationIgnored @LazyInjected(\.getMovieVideoUseCase) private var getMovieVideoUseCase
    @ObservationIgnored @LazyInjected(\.modelContainer) private var modelContainer

    var downloads: [Download] = []

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

    private func notificate(_ id: String, _ title: String, _ subtitle: String? = nil, _ category: String? = nil, _ userInfo: [AnyHashable: Any] = [:]) async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

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

            try? await UNUserNotificationCenter.current().add(request)
        } else if settings.authorizationStatus == .notDetermined {
            if let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]), granted {
                await notificate(id, title, subtitle, category, userInfo)
            }
        }
    }

    @ObservationIgnored
    private var isAccessAllowed: Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        return status == .authorized || status == .limited
    }

    private func requestPermission() async throws {
        guard !isAccessAllowed else { return }

        let authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

        guard authorizationStatus == .authorized || authorizationStatus == .limited else { throw HDrezkaError.photosDenied }
    }

    private func getAlbum(localizedTitle: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "localizedTitle = %@", localizedTitle)

        return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options).firstObject
    }

    private func getOrCreateAlbum(title: String, in folder: PHCollectionList? = nil) async throws -> PHAssetCollection {
        if let album = getAlbum(localizedTitle: title) { return album }

        try await PHPhotoLibrary.shared().performChanges {
            let album = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)

            if let folder {
                let listChangeRequest = PHCollectionListChangeRequest(for: folder)
                listChangeRequest?.addChildCollections([album.placeholderForCreatedAssetCollection] as NSArray)
            }
        }

        guard let album = getAlbum(localizedTitle: title) else { throw HDrezkaError.unknown }

        return album
    }

    private func saveVideo(url: URL) async throws -> PHAsset {
        var placeholder: PHObjectPlaceholder?

        try await PHPhotoLibrary.shared().performChanges {
            placeholder = PHAssetChangeRequest
                .creationRequestForAssetFromVideo(atFileURL: url)?
                .placeholderForCreatedAsset
        }

        guard let localIdentifier = placeholder?.localIdentifier else { throw HDrezkaError.unknown }

        let options = PHFetchOptions()
        options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue),
            NSPredicate(format: "localIdentifier = %@", localIdentifier),
        ])

        guard let asset = PHAsset.fetchAssets(with: options).firstObject else { throw HDrezkaError.unknown }

        return asset
    }

    private func getVideos(album: PHAssetCollection) -> [PHAsset] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let assets = PHAsset.fetchAssets(in: album, options: options)

        return assets.objects(at: IndexSet(integersIn: 0 ..< assets.count))
    }

    private func addVideoToAlbum(album: PHAssetCollection, video: PHAsset) async throws {
        guard !getVideos(album: album).contains(where: { $0.localIdentifier == video.localIdentifier }) else { return }

        try await PHPhotoLibrary.shared().performChanges {
            let addAssetRequest = PHAssetCollectionChangeRequest(for: album)
            let assets: NSArray = [video]
            addAssetRequest?.addAssets(assets)
        }
    }

    private func saveToPhotos(_ url: URL, _ data: DownloadData) async throws {
        try await requestPermission()

        let album = try await getOrCreateAlbum(title: "HDrezka")

        let video = try await saveVideo(url: url)

        try await addVideoToAlbum(album: album, video: video)

        try? FileManager.default.removeItem(at: url)

        await notificate(data.notificationId, String(localized: "key.download.success"), String(localized:
            "key.download.success.notification-\(data.name)"), "open", ["url": Const.photos.absoluteString])
    }

    func download(_ data: DownloadData) {
        if let retryData = data.retryData {
            if let season = data.season, let episode = data.episode {
                if let movieDestination = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?
                    .appending(path: "HDrezka", directoryHint: .isDirectory)
                    .appending(path: data.file, directoryHint: .notDirectory)
                {
                    getMovieVideoUseCase(voiceActing: data.acting, season: season, episode: episode, favs: data.details.favs)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            guard case let .failure(error) = completion else { return }

                            Task { [weak self] in
                                guard let self else { return }

                                await notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                            }
                        } receiveValue: { movie in
                            if movie.needPremium {
                                Task { [weak self] in
                                    guard let self else { return }

                                    await notificate(data.notificationId, String(localized: "key.download.needPremium"), String(localized: "key.download.needPremium.notification-\(data.name)"), "need_premium")
                                }
                            } else {
                                if Defaults[.isLoggedIn] {
                                    self.saveWatchingStateUseCase(voiceActing: data.acting, season: season, episode: episode, position: 0, total: 0)
                                        .sink { _ in } receiveValue: { _ in }
                                        .store(in: &self.subscriptions)
                                }

                                Task { @MainActor [weak self] in
                                    guard let self else { return }

                                    let modelContext = modelContainer.mainContext

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

                                if let movieUrl = movie.getClosestTo(quality: data.quality)?.first {
                                    Task { [weak self] in
                                        guard let self else { return }

                                        await notificate(data.notificationId, String(localized: "key.download.downloading"), String(localized: "key.download.downloading.notification-\(data.name)"), "cancel", ["id": data.notificationId])
                                    }

                                    let request = self.session.download(movieUrl, method: .get, headers: [.userAgent(Const.userAgent)], to: { _, _ in (movieDestination, [.createIntermediateDirectories, .removePreviousFile]) })
                                        .validate(statusCode: 200 ..< 400)
                                        .responseURL(queue: .main) { response in
                                            self.downloads.removeAll(where: { $0.id == data.notificationId })

                                            if let error = response.error {
                                                Task { [weak self] in
                                                    guard let self else { return }

                                                    if error.isExplicitlyCancelledError {
                                                        await notificate(data.notificationId, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(data.name)"), "retry", ["data": retryData])
                                                    } else {
                                                        await notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                                                    }
                                                }
                                            } else if let destination = response.value {
                                                Task.detached { [weak self] in
                                                    guard let self else { return }

                                                    do {
                                                        try await saveToPhotos(destination, data)

                                                        if data.all, let nextEpisode = season.episodes.element(after: episode) {
                                                            await MainActor.run {
                                                                self.download(data.newEpisede(nextEpisode))
                                                            }
                                                        }
                                                    } catch {
                                                        await notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
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
                    Task { [weak self] in
                        guard let self else { return }

                        await notificate(data.notificationId, String(localized: "key.download.failed"), String(localized:
                            "key.download.failed.notification-\(data.name)"), "retry", ["data": retryData])
                    }
                }
            } else if let season = data.season, let episode = season.episodes.first {
                download(data.newEpisede(episode))
            } else {
                if let movieDestination = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?
                    .appending(path: "HDrezka", directoryHint: .isDirectory)
                    .appending(path: data.file, directoryHint: .notDirectory)
                {
                    getMovieVideoUseCase(voiceActing: data.acting, season: nil, episode: nil, favs: data.details.favs)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            guard case let .failure(error) = completion else { return }

                            Task { [weak self] in
                                guard let self else { return }

                                await notificate(data.notificationId, String(localized: "key.download.failed"), String(localized:
                                    "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                            }
                        } receiveValue: { movie in
                            if movie.needPremium {
                                Task { [weak self] in
                                    guard let self else { return }

                                    await notificate(data.notificationId, String(localized: "key.download.needPremium"), String(localized: "key.download.needPremium.notification-\(data.name)"), "need_premium")
                                }
                            } else {
                                if Defaults[.isLoggedIn] {
                                    self.saveWatchingStateUseCase(voiceActing: data.acting, season: nil, episode: nil, position: 0, total: 0)
                                        .sink { _ in } receiveValue: { _ in }
                                        .store(in: &self.subscriptions)
                                }

                                Task { @MainActor [weak self] in
                                    guard let self else { return }

                                    let modelContext = modelContainer.mainContext

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

                                if let movieUrl = movie.getClosestTo(quality: data.quality)?.first {
                                    Task { [weak self] in
                                        guard let self else { return }

                                        await notificate(data.notificationId, String(localized: "key.download.downloading"), String(localized: "key.download.downloading.notification-\(data.name)"), "cancel", ["id": data.notificationId])
                                    }

                                    let request = self.session.download(movieUrl, method: .get, headers: [.userAgent(Const.userAgent)], to: { _, _ in (movieDestination, [.createIntermediateDirectories, .removePreviousFile]) })
                                        .validate(statusCode: 200 ..< 400)
                                        .responseURL(queue: .main) { response in
                                            self.downloads.removeAll(where: { $0.id == data.notificationId })
                                            if let error = response.error {
                                                Task { [weak self] in
                                                    guard let self else { return }

                                                    if error.isExplicitlyCancelledError {
                                                        await notificate(data.notificationId, String(localized: "key.download.canceled"), String(localized: "key.download.canceled.notification-\(data.name)"), "retry", ["data": retryData])
                                                    } else {
                                                        await notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
                                                    }
                                                }
                                            } else if let destination = response.value {
                                                Task.detached { [weak self] in
                                                    guard let self else { return }

                                                    do {
                                                        try await saveToPhotos(destination, data)
                                                    } catch {
                                                        await notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)-\(error.localizedDescription)"), "retry", ["data": retryData])
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
                    Task { [weak self] in
                        guard let self else { return }

                        await notificate(data.notificationId, String(localized: "key.download.failed"), String(localized: "key.download.failed.notification-\(data.name)"), "retry", ["data": retryData])
                    }
                }
            }
        } else {
            Task { [weak self] in
                guard let self else { return }

                await notificate(UUID().uuidString, String(localized: "key.download.failed"))
            }
        }
    }
}

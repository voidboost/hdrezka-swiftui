import ComposableArchitecture
import FirebaseAnalytics
import SwiftUI

struct DownloadSheetView: View {
    @Bindable var store: StoreOf<MovieSelectionFeature>

    private var details: MovieDetailed? { store.details }
    private var movie: MovieVideo? { store.movie }
    private var selectedActing: MovieVoiceActing? { store.selectedActing }
    private var selectedSeason: MovieSeason? { store.selectedSeason }
    private var selectedEpisode: MovieEpisode? { store.selectedEpisode }
    private var selectedQuality: String? { store.selectedQuality }
    private var selectedSubtitles: MovieSubtitles? { store.selectedSubtitles }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @SharedReader(.downloads) private var downloads
    @SharedReader(.isDownloaderRunning) private var isDownloaderRunning

    @State private var pendingDownload: DownloadData?
    @State private var isFolderImporterPresented: Bool = false

    var body: some View {
        MovieSelectionSheet(store: store, icon: "arrow.down.circle", description: "key.download.description", showsSubtitles: true) {
            MovieSelectionActionButton("key.download", isActive: selectedQuality != nil) {
                requestFolder(for: selection(all: false))
            }
            .disabled(isDownloading(selection(all: false)))

            if NSWorkspace.shared.urlForApplication(toOpen: ExternalDownloaders.folx.url) != nil {
                MovieSelectionActionButton(ExternalDownloaders.folx.localizedKey, isActive: selectedQuality != nil) {
                    store.send(.rememberSelection)

                    if let selectedQuality, let movie, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first, let selectedSubtitles, let subtitlesURL = URL(string: selectedSubtitles.link) {
                        openURL(
                            ExternalDownloaders.folx.url.appending(queryItems: [
                                .init(name: "urls", value: "\(movieURL.absoluteString)||\(subtitlesURL.absoluteString)"),
                                .init(name: "urlsCount", value: "2"),
                            ])
                        )
                    } else if let selectedQuality, let movie, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first {
                        openURL(
                            ExternalDownloaders.folx.url.appending(queryItems: [
                                .init(name: "urls", value: movieURL.absoluteString),
                                .init(name: "urlsCount", value: "1"),
                            ])
                        )
                    }
                }
            }

            if NSWorkspace.shared.urlForApplication(toOpen: ExternalDownloaders.motrix.url) != nil {
                MovieSelectionActionButton(ExternalDownloaders.motrix.localizedKey, isActive: selectedQuality != nil) {
                    store.send(.rememberSelection)

                    if let selectedQuality, let movie, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first, let selectedSubtitles, let subtitlesURL = URL(string: selectedSubtitles.link) {
                        openURL(
                            ExternalDownloaders.motrix.url.appending(queryItems: [
                                .init(name: "uris", value: "\(movieURL.absoluteString)\n\(subtitlesURL.absoluteString)"),
                            ])
                        )
                    } else if let selectedQuality, let movie, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first {
                        openURL(
                            ExternalDownloaders.motrix.url.appending(queryItems: [
                                .init(name: "uri", value: movieURL.absoluteString),
                            ])
                        )
                    }
                }
            }

            if let details, details.series != nil {
                MovieSelectionActionButton("key.download.season", isActive: selectedQuality != nil) {
                    requestFolder(for: selection(all: true))
                }
                .disabled(isDownloadingSeason(selection(all: true)))
            }
        }
        .fileImporter(isPresented: $isFolderImporterPresented, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
            defer { self.pendingDownload = nil }

            guard let pendingDownload, case let .success(urls) = result, let url = urls.first else { return }

            let isAccessing = url.startAccessingSecurityScopedResource()

            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            guard let folder = try? url.bookmarkData(options: .withSecurityScope) else { return }

            store.send(.downloadRequested(pendingDownload.withFolder(folder)))
        } onCancellation: {
            pendingDownload = nil
        }
        .fileDialogDefaultDirectory(FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.resolvingSymlinksInPath())
        .fileDialogMessage(pendingDownload.map { Text("key.download.folder-\($0.details.nameRussian)") })
        .fileDialogConfirmationLabel(Text("key.download"))
        .fileDialogCustomizationID("download")
        .onChange(of: isDownloaderRunning) {
            if !isDownloaderRunning {
                dismiss()
            }
        }
        .analyticsScreen(name: "download_sheet", class: "DownloadSheetView")
    }

    private func selection(all: Bool) -> DownloadData? {
        guard let details, let selectedActing, let selectedQuality else { return nil }

        if all, selectedSeason == nil { return nil }

        return DownloadData(details: details, acting: selectedActing, season: selectedSeason, episode: selectedEpisode, quality: selectedQuality, subtitles: selectedSubtitles, all: all)
    }

    private func requestFolder(for data: DownloadData?) {
        guard let data else { return }

        pendingDownload = data
        isFolderImporterPresented = true
    }

    private func isDownloading(_ data: DownloadData?) -> Bool {
        guard let data else { return false }

        return downloads.contains { $0.data.notificationId == data.notificationId }
    }

    private func isDownloadingSeason(_ data: DownloadData?) -> Bool {
        guard let data else { return false }

        return downloads.contains { $0.data.all && $0.data.isSameSeason(as: data) }
    }
}

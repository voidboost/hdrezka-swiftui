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
    @Environment(Downloader.self) private var downloader

    var body: some View {
        MovieSelectionSheet(store: store, icon: "arrow.down.circle", description: "key.download.description", showsSubtitles: true) {
            MovieSelectionActionButton("key.download", isActive: selectedQuality != nil) {
                if let details, let selectedActing, let selectedQuality {
                    downloader.download(.init(details: details, acting: selectedActing, season: selectedSeason, episode: selectedEpisode, quality: selectedQuality, subtitles: selectedSubtitles))
                }
            }
            .disabled(downloader.downloads.contains(where: {
                $0.data.notificationId == "\(details?.movieId ?? "")\(selectedSeason?.seasonId ?? "")\(selectedEpisode?.episodeId ?? "")\(selectedActing?.translatorId ?? "")\(selectedQuality ?? "")".base64Encoded || $0.data.notificationId == "\(details?.movieId ?? "")\(selectedSeason?.seasonId ?? "")\(selectedActing?.translatorId ?? "")\(selectedQuality ?? "")".base64Encoded
            }))

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
                    if let selectedActing, let selectedQuality, let selectedSeason {
                        downloader.download(.init(details: details, acting: selectedActing, season: selectedSeason, episode: selectedEpisode, quality: selectedQuality, subtitles: selectedSubtitles, all: true))
                    }
                }
                .disabled(downloader.downloads.contains(where: {
                    $0.data.notificationId == "\(details.movieId)\(selectedSeason?.seasonId ?? "")\(selectedActing?.translatorId ?? "")\(selectedQuality ?? "")".base64Encoded
                }))
            }
        }
        .onChange(of: downloader.isRunning) {
            if !downloader.isRunning {
                dismiss()
            }
        }
        .analyticsScreen(name: "download_sheet", class: "DownloadSheetView")
    }
}

import ComposableArchitecture
import FirebaseAnalytics
import SwiftUI

struct OpenExternalPlayerSheetView: View {
    @Bindable var store: StoreOf<MovieSelectionFeature>

    private var movie: MovieVideo? { store.movie }
    private var selectedQuality: String? { store.selectedQuality }
    private var selectedSubtitles: MovieSubtitles? { store.selectedSubtitles }

    @Environment(\.openURL) private var openURL

    var body: some View {
        MovieSelectionSheet(store: store, icon: "arrow.up.forward.app", description: "key.open.description", showsSubtitles: true) {
            if ExternalPlayers.isAnyInstalled {
                if NSWorkspace.shared.urlForApplication(toOpen: ExternalPlayers.iina.url) != nil {
                    MovieSelectionActionButton(ExternalPlayers.iina.localizedKey, isActive: selectedQuality != nil) {
                        store.send(.rememberSelection)

                        if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first?.hls, let selectedSubtitles, let subtitlesURL = URL(string: selectedSubtitles.link) {
                            openURL(
                                ExternalPlayers.iina.url.appending(queryItems: [
                                    .init(name: "url", value: movieURL.absoluteString),
                                    .init(name: "mpv_sub-files", value: subtitlesURL.absoluteString.replacingOccurrences(of: ":", with: "\\:")),
                                    .init(name: "new_window", value: "1"),
                                ])
                            )
                        } else if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first?.hls {
                            openURL(
                                ExternalPlayers.iina.url.appending(queryItems: [
                                    .init(name: "url", value: movieURL.absoluteString),
                                    .init(name: "new_window", value: "1"),
                                ])
                            )
                        }
                    }
                }

                if NSWorkspace.shared.urlForApplication(toOpen: ExternalPlayers.infuse.url) != nil {
                    MovieSelectionActionButton(ExternalPlayers.infuse.localizedKey, isActive: selectedQuality != nil) {
                        store.send(.rememberSelection)

                        if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first, let selectedSubtitles, let subtitlesURL = URL(string: selectedSubtitles.link) {
                            openURL(
                                ExternalPlayers.infuse.url.appending(queryItems: [
                                    .init(name: "url", value: movieURL.absoluteString),
                                    .init(name: "sub", value: subtitlesURL.absoluteString),
                                ])
                            )
                        } else if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first {
                            openURL(
                                ExternalPlayers.infuse.url.appending(queryItems: [
                                    .init(name: "url", value: movieURL.absoluteString),
                                ])
                            )
                        }
                    }
                }

                if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: ExternalPlayers.mpv.bundleIdentifier) {
                    MovieSelectionActionButton(ExternalPlayers.mpv.localizedKey, isActive: selectedQuality != nil) {
                        store.send(.rememberSelection)

                        if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first?.hls, let selectedSubtitles, let subtitlesURL = URL(string: selectedSubtitles.link) {
                            run(appURL, arguments: ["--sub-files=\(subtitlesURL.absoluteString.replacingOccurrences(of: ":", with: "\\:"))", movieURL.absoluteString])
                        } else if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first?.hls {
                            run(appURL, arguments: [movieURL.absoluteString])
                        }
                    }
                }

                if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: ExternalPlayers.vlc.bundleIdentifier) {
                    MovieSelectionActionButton(ExternalPlayers.vlc.localizedKey, isActive: selectedQuality != nil) {
                        store.send(.rememberSelection)

                        if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first?.hls, let selectedSubtitles, let subtitlesURL = URL(string: selectedSubtitles.link), subtitlesURL.pathExtension == "srt" {
                            run(appURL, arguments: ["--sub-file=\(subtitlesURL.absoluteString)", movieURL.absoluteString])
                        } else if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.first?.hls {
                            run(appURL, arguments: [movieURL.absoluteString])
                        }
                    }
                }
            } else {
                Text("key.open.empty")
                    .frame(width: 250, height: 30)
                    .foregroundStyle(.white)
                    .contentShape(.rect(cornerRadius: 6))
                    .background(Color.accentColor, in: .rect(cornerRadius: 6))
            }
        }
        .analyticsScreen(name: "open_external_player_sheet", class: "OpenExternalPlayerSheetView")
    }

    private func run(_ appURL: URL, arguments: [String]) {
        do {
            try Process.run(
                appURL.appending(path: "Contents", directoryHint: .isDirectory).appending(path: "MacOS", directoryHint: .isDirectory).appending(path: appURL.deletingPathExtension().lastPathComponent, directoryHint: .notDirectory),
                arguments: arguments
            )
        } catch {
            store.send(.showError(error))
        }
    }
}

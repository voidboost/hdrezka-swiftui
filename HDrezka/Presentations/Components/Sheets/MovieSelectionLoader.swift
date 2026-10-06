import Combine
import Defaults
import Dependencies
import SQLiteData
import SwiftUI

struct MovieSelectionLoader: ViewModifier {
    @Dependency(\.getMovieDetailsUseCase) private var getMovieDetailsUseCase
    @Dependency(\.getMovieVideoUseCase) private var getMovieVideoUseCase
    @Dependency(\.getSeriesSeasonsUseCase) private var getSeriesSeasonsUseCase

    @Environment(\.dismiss) private var dismiss

    @Environment(AppState.self) private var appState

    @FetchOne private var selectPosition: SelectPosition?

    @Default(.isUserPremium) private var isUserPremium
    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.defaultQuality) private var defaultQuality

    @State private var detailsRequest: AnyCancellable?
    @State private var seasonsRequest: AnyCancellable?
    @State private var videoRequest: AnyCancellable?

    let id: String

    @Binding var details: MovieDetailed?
    @Binding var seasons: [MovieSeason]?
    @Binding var selectedActing: MovieVoiceActing?
    @Binding var selectedSeason: MovieSeason?
    @Binding var selectedEpisode: MovieEpisode?
    @Binding var selectedQuality: String?
    @Binding var movie: MovieVideo?
    @Binding var error: Error?
    @Binding var isErrorPresented: Bool

    var selectedSubtitles: Binding<MovieSubtitles?>?

    func body(content: Content) -> some View {
        content
            .onAppear {
                detailsRequest = getMovieDetailsUseCase(movieId: id)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        show(error)
                    } receiveValue: { details in
                        Task { @MainActor in
                            if let movieId = details.movieId.id {
                                _ = try? await $selectPosition.load(
                                    SelectPosition.where { $0.id.eq(movieId) }
                                )
                            }

                            withAnimation(.easeInOut) {
                                self.details = details
                            }
                        }
                    }
            }
            .onChange(of: details) {
                if let details, let acting = details.voiceActing {
                    let available = acting.filter { isUserPremium != nil || !$0.isPremium }

                    withAnimation(.easeInOut) {
                        selectedActing = if !isLoggedIn,
                                            let position = selectPosition,
                                            let first = available.first(where: { $0.translatorId == position.acting })
                        {
                            first
                        } else if let series = details.series,
                                  let first = available.first(where: { $0.translatorId == series.acting })
                        {
                            first
                        } else if let first = available.first(where: { $0.isSelected }) {
                            first
                        } else if let first = available.first {
                            first
                        } else {
                            acting.first
                        }
                    }
                }
            }
            .onChange(of: selectedActing) {
                seasonsRequest = nil
                videoRequest = nil

                withAnimation(.easeInOut) {
                    selectedSeason = nil
                    selectedEpisode = nil
                    selectedQuality = nil
                    seasons = nil
                    movie = nil
                }

                guard let details, let selectedActing else { return }

                if details.series != nil {
                    guard let movieId = details.movieId.id else {
                        if !isErrorPresented {
                            isErrorPresented = true
                        }

                        return
                    }

                    seasonsRequest = getSeriesSeasonsUseCase(movieId: movieId, voiceActing: selectedActing, favs: details.favs)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            guard case let .failure(error) = completion else { return }

                            show(error)
                        } receiveValue: { seasons in
                            withAnimation(.easeInOut) {
                                self.seasons = seasons

                                selectedSeason = if !isLoggedIn,
                                                    let position = selectPosition,
                                                    let first = seasons.first(where: { $0.seasonId == position.season })
                                {
                                    first
                                } else if let series = details.series,
                                          let first = seasons.first(where: { $0.seasonId == series.season })
                                {
                                    first
                                } else if let first = seasons.first(where: { $0.isSelected }) {
                                    first
                                } else {
                                    seasons.first
                                }
                            }
                        }
                } else {
                    loadVideo(details: details, acting: selectedActing, season: nil, episode: nil)
                }
            }
            .onChange(of: selectedSeason) {
                withAnimation(.easeInOut) {
                    selectedQuality = nil
                    movie = nil

                    selectedEpisode = if !isLoggedIn,
                                         let position = selectPosition,
                                         let first = selectedSeason?.episodes.first(where: { $0.episodeId == position.episode })
                    {
                        first
                    } else if let series = details?.series,
                              let first = selectedSeason?.episodes.first(where: { $0.episodeId == series.episode })
                    {
                        first
                    } else if let first = selectedSeason?.episodes.first(where: { $0.isSelected }) {
                        first
                    } else {
                        selectedSeason?.episodes.first
                    }
                }
            }
            .onChange(of: selectedEpisode) {
                videoRequest = nil

                withAnimation(.easeInOut) {
                    selectedQuality = nil
                    movie = nil
                }

                if let details, let selectedSeason, let selectedEpisode, let selectedActing {
                    loadVideo(details: details, acting: selectedActing, season: selectedSeason, episode: selectedEpisode)
                }
            }
    }

    private func loadVideo(details: MovieDetailed, acting: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?) {
        videoRequest = getMovieVideoUseCase(voiceActing: acting, season: season, episode: episode, favs: details.favs)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                show(error)
            } receiveValue: { movie in
                if movie.needPremium {
                    dismiss()

                    appState.isPremiumPresented = true
                } else {
                    withAnimation(.easeInOut) {
                        self.movie = movie

                        let qualities = movie.getAvailableQualities()

                        if defaultQuality != .ask,
                           defaultQuality != .highest,
                           qualities.contains(defaultQuality.rawValue)
                        {
                            selectedQuality = defaultQuality.rawValue
                        } else if defaultQuality == .highest,
                                  let highest = qualities.last
                        {
                            selectedQuality = highest
                        }

                        selectedSubtitles?.wrappedValue = movie.subtitles.first(where: { $0.lang == selectPosition?.subtitles?.replacingOccurrences(of: "uk", with: "ua") })
                    }
                }
            }
    }

    private func show(_ error: Error) {
        self.error = error
        isErrorPresented = true
    }
}

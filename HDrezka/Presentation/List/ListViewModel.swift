import Combine
import Defaults
import FactoryKit
import SwiftUI

class ListViewModel: ObservableObject {
//    @Injected(\.getFeaturedMoviesUseCase) private var getFeaturedMoviesUseCase
    @Injected(\.getHotMoviesUseCase) private var getHotMoviesUseCase
    @Injected(\.getLatestMoviesByCountryUseCase) private var getLatestMoviesByCountryUseCase
    @Injected(\.getLatestMoviesByGenreUseCase) private var getLatestMoviesByGenreUseCase
    @Injected(\.getLatestMoviesUseCase) private var getLatestMoviesUseCase
    @Injected(\.getLatestNewestMoviesUseCase) private var getLatestNewestMoviesUseCase
    @Injected(\.getMovieListUseCase) private var getMovieListUseCase
    @Injected(\.getPopularMoviesByCountryUseCase) private var getPopularMoviesByCountryUseCase
    @Injected(\.getPopularMoviesByGenreUseCase) private var getPopularMoviesByGenreUseCase
    @Injected(\.getPopularMoviesUseCase) private var getPopularMoviesUseCase
    @Injected(\.getPopularNewestMoviesUseCase) private var getPopularNewestMoviesUseCase
    @Injected(\.getSoonMoviesByCountryUseCase) private var getSoonMoviesByCountryUseCase
    @Injected(\.getSoonMoviesByGenreUseCase) private var getSoonMoviesByGenreUseCase
    @Injected(\.getSoonMoviesUseCase) private var getSoonMoviesUseCase
    @Injected(\.getWatchingNowMoviesByCountryUseCase) private var getWatchingNowMoviesByCountryUseCase
    @Injected(\.getWatchingNowMoviesByGenreUseCase) private var getWatchingNowMoviesByGenreUseCase
    @Injected(\.getWatchingNowMoviesUseCase) private var getWatchingNowMoviesUseCase
    @Injected(\.getWatchingNowNewestMoviesUseCase) private var getWatchingNowNewestMoviesUseCase
    @Injected(\.getLatestMoviesInCollectionUseCase) private var getLatestMoviesInCollectionUseCase
    @Injected(\.getSoonMoviesInCollectionUseCase) private var getSoonMoviesInCollectionUseCase
    @Injected(\.getPopularMoviesInCollectionUseCase) private var getPopularMoviesInCollectionUseCase
    @Injected(\.getWatchingNowMoviesInCollectionUseCase) private var getWatchingNowMoviesInCollectionUseCase

    private var subscriptions: Set<AnyCancellable> = []

    @Published var title: String?
    @Published var state: DataState<[MovieSimple]> = .loading
    @Published var paginationState: DataPaginationState = .idle

    private var page = 1

    private func getData(movies: [MovieSimple]?, list: MovieList?, country: MovieCountry?, genre: MovieGenre?, collection: MoviesCollection?, category: Categories?, filterGenre: Genres?, filter: Filters?, newFilter: NewFilters?, isInitial: Bool = true) {
        if let list {
            getMovieListUseCase(listId: list.listId, page: page)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        if isInitial {
                            self.state = .error(error as NSError)
                        } else {
                            self.paginationState = .error(error as NSError)
                        }
                    }
                } receiveValue: { result in
                    self.page += 1

                    withAnimation(.easeInOut) {
                        if isInitial {
                            if !result.0.isEmpty {
                                self.title = result.0
                            }
                            self.state = .data(result.1)
                        } else {
                            self.state.append(result.1)
                            self.paginationState = .idle
                        }
                    }
                }
                .store(in: &subscriptions)
        } else if let movies {
            if Defaults[.navigationAnimation] {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeInOut) {
                        self.state = .data(movies)
                    }
                }
            } else {
                withAnimation(.easeInOut) {
                    self.state = .data(movies)
                }
            }
        } else if let country, let filterGenre, let filter {
            getPublisher(country: country, filterGenre: filterGenre, filter: filter)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        if isInitial {
                            self.state = .error(error as NSError)
                        } else {
                            self.paginationState = .error(error as NSError)
                        }
                    }
                } receiveValue: { result in
                    self.page += 1

                    withAnimation(.easeInOut) {
                        if isInitial {
                            self.state = .data(result)
                        } else {
                            self.state.append(result)
                            self.paginationState = .idle
                        }
                    }
                }
                .store(in: &subscriptions)
        } else if let genre, let filter {
            getPublisher(genre: genre, filter: filter)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        if isInitial {
                            self.state = .error(error as NSError)
                        } else {
                            self.paginationState = .error(error as NSError)
                        }
                    }
                } receiveValue: { result in
                    self.page += 1

                    withAnimation(.easeInOut) {
                        if isInitial {
                            self.state = .data(result)
                        } else {
                            self.state.append(result)
                            self.paginationState = .idle
                        }
                    }
                }
                .store(in: &subscriptions)
        } else if let category, let filterGenre {
            getPublisher(category: category, filterGenre: filterGenre, newFilter: newFilter)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        if isInitial {
                            self.state = .error(error as NSError)
                        } else {
                            self.paginationState = .error(error as NSError)
                        }
                    }
                } receiveValue: { result in
                    self.page += 1

                    withAnimation(.easeInOut) {
                        if isInitial {
                            self.state = .data(result)
                        } else {
                            self.state.append(result)
                            self.paginationState = .idle
                        }
                    }
                }
                .store(in: &subscriptions)
        } else if let collection, let filter {
            getPublisher(collection: collection, filter: filter)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        if isInitial {
                            self.state = .error(error as NSError)
                        } else {
                            self.paginationState = .error(error as NSError)
                        }
                    }
                } receiveValue: { result in
                    self.page += 1

                    withAnimation(.easeInOut) {
                        if isInitial {
                            self.state = .data(result)
                        } else {
                            self.state.append(result)
                            self.paginationState = .idle
                        }
                    }
                }
                .store(in: &subscriptions)
        } else {
            withAnimation(.easeInOut) {
                if isInitial {
                    self.state = .error(NSError())
                } else {
                    self.paginationState = .error(NSError())
                }
            }
        }
    }

    private func getPublisher(country: MovieCountry, filterGenre: Genres, filter: Filters) -> AnyPublisher<[MovieSimple], Error> {
        switch filter {
        case .latest:
            getLatestMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
        case .popular:
            getPopularMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
        case .soon:
            getSoonMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
        case .watching:
            getWatchingNowMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
        }
    }

    private func getPublisher(genre: MovieGenre, filter: Filters) -> AnyPublisher<[MovieSimple], Error> {
        switch filter {
        case .latest:
            getLatestMoviesByGenreUseCase(genreId: genre.genreId, page: page)
        case .popular:
            getPopularMoviesByGenreUseCase(genreId: genre.genreId, page: page)
        case .soon:
            getSoonMoviesByGenreUseCase(genreId: genre.genreId, page: page)
        case .watching:
            getWatchingNowMoviesByGenreUseCase(genreId: genre.genreId, page: page)
        }
    }

    private func getPublisher(category: Categories, filterGenre: Genres, newFilter: NewFilters?) -> AnyPublisher<[MovieSimple], Error> {
        switch category {
        case .hot:
            getHotMoviesUseCase(genre: filterGenre.genreCode)
//        case .featured:
//            getFeaturedMoviesUseCase(page: page, genre: filterGenre.genreCode)
        case .watchingNow:
            getWatchingNowMoviesUseCase(page: page, genre: filterGenre.genreCode)
        case .newest:
            if let newFilter {
                switch newFilter {
                case .latest:
                    getLatestNewestMoviesUseCase(page: page, genre: filterGenre.genreCode)
                case .popular:
                    getPopularNewestMoviesUseCase(page: page, genre: filterGenre.genreCode)
                case .watching:
                    getWatchingNowNewestMoviesUseCase(page: page, genre: filterGenre.genreCode)
                }
            } else {
                getLatestNewestMoviesUseCase(page: page, genre: filterGenre.genreCode)
            }
        case .latest:
            getLatestMoviesUseCase(page: page, genre: filterGenre.genreCode)
        case .popular:
            getPopularMoviesUseCase(page: page, genre: filterGenre.genreCode)
        case .soon:
            getSoonMoviesUseCase(page: page, genre: filterGenre.genreCode)
        }
    }

    private func getPublisher(collection: MoviesCollection, filter: Filters) -> AnyPublisher<[MovieSimple], Error> {
        switch filter {
        case .latest:
            getLatestMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
        case .popular:
            getPopularMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
        case .soon:
            getSoonMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
        case .watching:
            getWatchingNowMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
        }
    }

    func load(movies: [MovieSimple]?, list: MovieList?, country: MovieCountry?, genre: MovieGenre?, collection: MoviesCollection?, category: Categories?, filterGenre: Genres?, filter: Filters?, newFilter: NewFilters?) {
        state = .loading
        paginationState = .idle
        page = 1

        getData(movies: movies, list: list, country: country, genre: genre, collection: collection, category: category, filterGenre: filterGenre, filter: filter, newFilter: newFilter)
    }

    func loadMore(movies: [MovieSimple]?, list: MovieList?, country: MovieCountry?, genre: MovieGenre?, collection: MoviesCollection?, category: Categories?, filterGenre: Genres?, filter: Filters?, newFilter: NewFilters?) {
        guard paginationState == .idle, movies == nil, category != .hot else { return }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        getData(movies: movies, list: list, country: country, genre: genre, collection: collection, category: category, filterGenre: filterGenre, filter: filter, newFilter: newFilter, isInitial: false)
    }
}

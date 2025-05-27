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

    private func getMovies(movies: [MovieSimple]? = nil, list: MovieList? = nil, country: MovieCountry? = nil, genre: MovieGenre? = nil, collection: MoviesCollection? = nil, category: Categories? = nil, filterGenre: Genres? = nil, filter: Filters? = nil, newFilter: NewFilters? = nil) {
        state = .loading
        paginationState = .idle
        page = 1

        if let list {
            getMovieListUseCase(listId: list.listId, page: page)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.state = .error(error as NSError)
                    }
                } receiveValue: { result in
                    withAnimation(.easeInOut) {
                        if !result.0.isEmpty {
                            self.title = result.0
                        }
                        self.state = .data(result.1)
                        self.page += 1
                    }
                }
                .store(in: &subscriptions)
        }

        if let movies {
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
        }

        if let country, let filterGenre, let filter {
            let publisher = switch filter {
            case .latest:
                getLatestMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
            case .popular:
                getPopularMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
            case .soon:
                getSoonMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
            case .watching:
                getWatchingNowMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
            }

            publisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.state = .error(error as NSError)
                    }
                } receiveValue: { result in
                    withAnimation(.easeInOut) {
                        self.state = .data(result)
                        self.page += 1
                    }
                }
                .store(in: &subscriptions)
        }

        if let genre, let filter {
            let publisher = switch filter {
            case .latest:
                getLatestMoviesByGenreUseCase(genreId: genre.genreId, page: page)
            case .popular:
                getPopularMoviesByGenreUseCase(genreId: genre.genreId, page: page)
            case .soon:
                getSoonMoviesByGenreUseCase(genreId: genre.genreId, page: page)
            case .watching:
                getWatchingNowMoviesByGenreUseCase(genreId: genre.genreId, page: page)
            }

            publisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.state = .error(error as NSError)
                    }
                } receiveValue: { result in
                    withAnimation(.easeInOut) {
                        self.state = .data(result)
                        self.page += 1
                    }
                }
                .store(in: &subscriptions)
        }

        if let category, let filterGenre {
            let publisher = switch category {
            case .hot:
                getHotMoviesUseCase(genre: filterGenre.genreCode)
//            case .featured:
//                getFeaturedMoviesUseCase(page: page, genre: filterGenre.genreCode)
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

            publisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.state = .error(error as NSError)
                    }
                } receiveValue: { result in
                    withAnimation(.easeInOut) {
                        self.state = .data(result)
                        self.page += 1
                    }
                }
                .store(in: &subscriptions)
        }

        if let collection, let filter {
            let publisher = switch filter {
            case .latest:
                getLatestMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
            case .popular:
                getPopularMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
            case .soon:
                getSoonMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
            case .watching:
                getWatchingNowMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
            }

            publisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.state = .error(error as NSError)
                    }
                } receiveValue: { result in
                    withAnimation(.easeInOut) {
                        self.state = .data(result)
                        self.page += 1
                    }
                }
                .store(in: &subscriptions)
        }
    }

    private func loadMore(movies: [MovieSimple]? = nil, list: MovieList? = nil, country: MovieCountry? = nil, genre: MovieGenre? = nil, collection: MoviesCollection? = nil, category: Categories? = nil, filterGenre: Genres? = nil, filter: Filters? = nil, newFilter: NewFilters? = nil) {
        guard paginationState == .idle, movies == nil, category != .hot else {
            return
        }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        if let list {
            getMovieListUseCase(listId: list.listId, page: page)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.paginationState = .error(error as NSError)
                    }
                } receiveValue: { result in
                    withAnimation(.easeInOut) {
                        self.state.append(result.1)
                        self.paginationState = .idle
                    }
                    self.page += 1
                }
                .store(in: &subscriptions)
        }

        if let c = country, let g = filterGenre, let f = filter {
            let publisher = switch f {
            case .latest:
                getLatestMoviesByCountryUseCase(countryId: c.countryId, genre: g.genreCode, page: page)
            case .popular:
                getPopularMoviesByCountryUseCase(countryId: c.countryId, genre: g.genreCode, page: page)
            case .soon:
                getSoonMoviesByCountryUseCase(countryId: c.countryId, genre: g.genreCode, page: page)
            case .watching:
                getWatchingNowMoviesByCountryUseCase(countryId: c.countryId, genre: g.genreCode, page: page)
            }

            publisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.paginationState = .error(error as NSError)
                    }
                } receiveValue: { result in
                    withAnimation(.easeInOut) {
                        self.state.append(result)
                        self.paginationState = .idle
                    }
                    self.page += 1
                }
                .store(in: &subscriptions)
        }

        if let g = genre, let f = filter {
            let publisher = switch f {
            case .latest:
                getLatestMoviesByGenreUseCase(genreId: g.genreId, page: page)
            case .popular:
                getPopularMoviesByGenreUseCase(genreId: g.genreId, page: page)
            case .soon:
                getSoonMoviesByGenreUseCase(genreId: g.genreId, page: page)
            case .watching:
                getWatchingNowMoviesByGenreUseCase(genreId: g.genreId, page: page)
            }

            publisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.paginationState = .error(error as NSError)
                    }
                } receiveValue: { result in
                    withAnimation(.easeInOut) {
                        self.state.append(result)
                        self.paginationState = .idle
                    }
                    self.page += 1
                }
                .store(in: &subscriptions)
        }

        if let c = category, let g = filterGenre {
            let publisher = switch c {
            case .hot:
                getHotMoviesUseCase(genre: g.genreCode)
//            case .featured:
//                getFeaturedMoviesUseCase(page: page, genre: g.genreCode)
            case .watchingNow:
                getWatchingNowMoviesUseCase(page: page, genre: g.genreCode)
            case .newest:
                if let newFilter {
                    switch newFilter {
                    case .latest:
                        getLatestNewestMoviesUseCase(page: page, genre: g.genreCode)
                    case .popular:
                        getPopularNewestMoviesUseCase(page: page, genre: g.genreCode)
                    case .watching:
                        getWatchingNowNewestMoviesUseCase(page: page, genre: g.genreCode)
                    }
                } else {
                    getLatestNewestMoviesUseCase(page: page, genre: g.genreCode)
                }
            case .latest:
                getLatestMoviesUseCase(page: page, genre: g.genreCode)
            case .popular:
                getPopularMoviesUseCase(page: page, genre: g.genreCode)
            case .soon:
                getSoonMoviesUseCase(page: page, genre: g.genreCode)
            }

            publisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.paginationState = .error(error as NSError)
                    }
                } receiveValue: { result in
                    withAnimation(.easeInOut) {
                        self.state.append(result)
                        self.paginationState = .idle
                    }
                    self.page += 1
                }
                .store(in: &subscriptions)
        }

        if let c = collection, let f = filter {
            let publisher = switch f {
            case .latest:
                getLatestMoviesInCollectionUseCase(collectionId: c.collectionId, page: page)
            case .popular:
                getPopularMoviesInCollectionUseCase(collectionId: c.collectionId, page: page)
            case .soon:
                getSoonMoviesInCollectionUseCase(collectionId: c.collectionId, page: page)
            case .watching:
                getWatchingNowMoviesInCollectionUseCase(collectionId: c.collectionId, page: page)
            }

            publisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.paginationState = .error(error as NSError)
                    }
                } receiveValue: { result in
                    withAnimation(.easeInOut) {
                        self.state.append(result)
                        self.paginationState = .idle
                    }
                    self.page += 1
                }
                .store(in: &subscriptions)
        }
    }

    func reload(category: Categories, genre: Genres, newFilter: NewFilters) {
        getMovies(category: category, filterGenre: genre, newFilter: newFilter)
    }

    func nextPage(category: Categories, genre: Genres, newFilter: NewFilters) {
        loadMore(category: category, filterGenre: genre, newFilter: newFilter)
    }

    func reload(collection: MoviesCollection, filter: Filters) {
        getMovies(collection: collection, filter: filter)
    }

    func nextPage(collection: MoviesCollection, filter: Filters) {
        loadMore(collection: collection, filter: filter)
    }

    func reload(genre: MovieGenre, filter: Filters) {
        getMovies(genre: genre, filter: filter)
    }

    func nextPage(genre: MovieGenre, filter: Filters) {
        loadMore(genre: genre, filter: filter)
    }

    func reload(country: MovieCountry, genre: Genres, filter: Filters) {
        getMovies(country: country, filterGenre: genre, filter: filter)
    }

    func nextPage(country: MovieCountry, genre: Genres, filter: Filters) {
        loadMore(country: country, filterGenre: genre, filter: filter)
    }

    func reload(movies: [MovieSimple]) {
        getMovies(movies: movies)
    }

    func nextPage(movies: [MovieSimple]) {
        loadMore(movies: movies)
    }

    func reload(list: MovieList) {
        getMovies(list: list)
    }

    func nextPage(list: MovieList) {
        loadMore(list: list)
    }
}

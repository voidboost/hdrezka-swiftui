import Combine
import Defaults
import FactoryKit
import SwiftUI

@Observable
class ListViewModel {
    @ObservationIgnored
    @Injected(\.movieLists)
    private var movieLists
    @ObservationIgnored
    @Injected(\.collections)
    private var collections

    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []

    var title = String(localized: "key.list")
    var state: DataState<[MovieSimple]> = .loading
    var paginationState: DataPaginationState = .idle

    @ObservationIgnored
    private var page = 1

    private func getMovies(movies: [MovieSimple]? = nil, list: MovieList? = nil, country: MovieCountry? = nil, genre: MovieGenre? = nil, collection: MoviesCollection? = nil, category: Categories? = nil, filterGenre: Genres? = nil, filter: Filters? = nil, newFilter: NewFilters? = nil) {
        state = .loading
        paginationState = .idle
        page = 1

        if let list {
            movieLists
                .getMovieList(listId: list.listId, page: page)
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
                movieLists.getLatestMoviesByCountry(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
            case .popular:
                movieLists.getPopularMoviesByCountry(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
            case .soon:
                movieLists.getSoonMoviesByCountry(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
            case .watching:
                movieLists.getWatchingNowMoviesByCountry(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
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
                movieLists.getLatestMoviesByGenre(genreId: genre.genreId, page: page)
            case .popular:
                movieLists.getPopularMoviesByGenre(genreId: genre.genreId, page: page)
            case .soon:
                movieLists.getSoonMoviesByGenre(genreId: genre.genreId, page: page)
            case .watching:
                movieLists.getWatchingNowMoviesByGenre(genreId: genre.genreId, page: page)
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
                movieLists.getHotMovies(genre: filterGenre.genreCode)
//            case .featured:
//                 movieLists.getFeaturedMovies(page: page, genre: filterGenre.genreCode)
            case .watchingNow:
                movieLists.getWatchingNowMovies(page: page, genre: filterGenre.genreCode)
            case .newest:
                if let newFilter {
                    switch newFilter {
                    case .latest:
                        movieLists.getLatestNewestMovies(page: page, genre: filterGenre.genreCode)
                    case .popular:
                        movieLists.getPopularNewestMovies(page: page, genre: filterGenre.genreCode)
                    case .watching:
                        movieLists.getWatchingNowNewestMovies(page: page, genre: filterGenre.genreCode)
                    }
                } else {
                    movieLists.getLatestNewestMovies(page: page, genre: filterGenre.genreCode)
                }
            case .latest:
                movieLists.getLatestMovies(page: page, genre: filterGenre.genreCode)
            case .popular:
                movieLists.getPopularMovies(page: page, genre: filterGenre.genreCode)
            case .soon:
                movieLists.getSoonMovies(page: page, genre: filterGenre.genreCode)
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
                collections.getLatestMoviesInCollection(collectionId: collection.collectionId, page: page)
            case .popular:
                collections.getPopularMoviesInCollection(collectionId: collection.collectionId, page: page)
            case .soon:
                collections.getSoonMoviesInCollection(collectionId: collection.collectionId, page: page)
            case .watching:
                collections.getWatchingNowMoviesInCollection(collectionId: collection.collectionId, page: page)
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
            movieLists
                .getMovieList(listId: list.listId, page: page)
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
                movieLists.getLatestMoviesByCountry(countryId: c.countryId, genre: g.genreCode, page: page)
            case .popular:
                movieLists.getPopularMoviesByCountry(countryId: c.countryId, genre: g.genreCode, page: page)
            case .soon:
                movieLists.getSoonMoviesByCountry(countryId: c.countryId, genre: g.genreCode, page: page)
            case .watching:
                movieLists.getWatchingNowMoviesByCountry(countryId: c.countryId, genre: g.genreCode, page: page)
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
                movieLists.getLatestMoviesByGenre(genreId: g.genreId, page: page)
            case .popular:
                movieLists.getPopularMoviesByGenre(genreId: g.genreId, page: page)
            case .soon:
                movieLists.getSoonMoviesByGenre(genreId: g.genreId, page: page)
            case .watching:
                movieLists.getWatchingNowMoviesByGenre(genreId: g.genreId, page: page)
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
                movieLists.getHotMovies(genre: g.genreCode)
//            case .featured:
//                 movieLists.getFeaturedMovies(page: page, genre: g.genreCode)
            case .watchingNow:
                movieLists.getWatchingNowMovies(page: page, genre: g.genreCode)
            case .newest:
                if let newFilter {
                    switch newFilter {
                    case .latest:
                        movieLists.getLatestNewestMovies(page: page, genre: g.genreCode)
                    case .popular:
                        movieLists.getPopularNewestMovies(page: page, genre: g.genreCode)
                    case .watching:
                        movieLists.getWatchingNowNewestMovies(page: page, genre: g.genreCode)
                    }
                } else {
                    movieLists.getLatestNewestMovies(page: page, genre: g.genreCode)
                }
            case .latest:
                movieLists.getLatestMovies(page: page, genre: g.genreCode)
            case .popular:
                movieLists.getPopularMovies(page: page, genre: g.genreCode)
            case .soon:
                movieLists.getSoonMovies(page: page, genre: g.genreCode)
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
                collections.getLatestMoviesInCollection(collectionId: c.collectionId, page: page)
            case .popular:
                collections.getPopularMoviesInCollection(collectionId: c.collectionId, page: page)
            case .soon:
                collections.getSoonMoviesInCollection(collectionId: c.collectionId, page: page)
            case .watching:
                collections.getWatchingNowMoviesInCollection(collectionId: c.collectionId, page: page)
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

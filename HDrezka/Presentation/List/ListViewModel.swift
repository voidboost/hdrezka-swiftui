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

    private let list: MovieList?
    private let country: MovieCountry?
    private let genre: MovieGenre?
    private let category: Categories?
    private let collection: MoviesCollection?
    private let movies: [MovieSimple]?

    init(list: MovieList? = nil, country: MovieCountry? = nil, genre: MovieGenre? = nil, category: Categories? = nil, collection: MoviesCollection? = nil, movies: [MovieSimple]? = nil, title: String? = nil) {
        self.list = list
        self.country = country
        self.genre = genre
        self.category = category
        self.collection = collection
        self.movies = movies

        self.title = if let title = list?.name, !title.isEmpty {
            title
        } else if let title = country?.name, !title.isEmpty {
            title
        } else if let title = genre?.name, !title.isEmpty {
            title
        } else if let title = category?.localized, !title.isEmpty {
            title
        } else if let title = collection?.name, !title.isEmpty {
            title
        } else if let title, !title.isEmpty {
            title
        } else {
            String(localized: "key.list")
        }
    }

    var isCustomMovies: Bool {
        movies != nil
    }

    var isList: Bool {
        list != nil
    }

    var isCountry: Bool {
        country != nil
    }

    var isGenre: Bool {
        genre != nil
    }

    var isCategory: Bool {
        category != nil
    }

    func isCategory(_ category: Categories) -> Bool {
        self.category == category
    }

    var isCollection: Bool {
        collection != nil
    }

    private var subscriptions: Set<AnyCancellable> = []

    @Published private(set) var state: DataState<[MovieSimple]> = .loading
    @Published private(set) var paginationState: DataPaginationState = .idle

    @Published private(set) var title: String

    @Published var filterGenre = Genres.all
    @Published var filter = Filters.latest
    @Published var newFilter = NewFilters.latest

    private var page = 1

    private func getData(isInitial: Bool = true) {
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
        } else if let country {
            getPublisher(country: country)
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
        } else if let genre {
            getPublisher(genre: genre)
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
        } else if let category {
            getPublisher(category: category)
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
        } else if let collection {
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

    private func getPublisher(country: MovieCountry) -> AnyPublisher<[MovieSimple], Error> {
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

    private func getPublisher(genre: MovieGenre) -> AnyPublisher<[MovieSimple], Error> {
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

    private func getPublisher(category: Categories) -> AnyPublisher<[MovieSimple], Error> {
        switch category {
        case .hot:
            getHotMoviesUseCase(genre: filterGenre.genreCode)
//        case .featured:
//            getFeaturedMoviesUseCase(page: page, genre: filterGenre.genreCode)
        case .watchingNow:
            getWatchingNowMoviesUseCase(page: page, genre: filterGenre.genreCode)
        case .newest:
            switch newFilter {
            case .latest:
                getLatestNewestMoviesUseCase(page: page, genre: filterGenre.genreCode)
            case .popular:
                getPopularNewestMoviesUseCase(page: page, genre: filterGenre.genreCode)
            case .watching:
                getWatchingNowNewestMoviesUseCase(page: page, genre: filterGenre.genreCode)
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

    func load() {
        state = .loading
        paginationState = .idle
        page = 1

        getData()
    }

    func loadMore() {
        guard paginationState == .idle, !isCustomMovies, !isCategory(.hot) else { return }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        getData(isInitial: false)
    }
}

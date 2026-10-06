import Combine
import Defaults
import Dependencies
import SwiftUI

@Observable
class ListViewModel {
//    @ObservationIgnored @Dependency(\.getFeaturedMoviesUseCase) private var getFeaturedMoviesUseCase
    @ObservationIgnored @Dependency(\.getHotMoviesUseCase) private var getHotMoviesUseCase
    @ObservationIgnored @Dependency(\.getLatestMoviesByCountryUseCase) private var getLatestMoviesByCountryUseCase
    @ObservationIgnored @Dependency(\.getLatestMoviesByGenreUseCase) private var getLatestMoviesByGenreUseCase
    @ObservationIgnored @Dependency(\.getLatestMoviesUseCase) private var getLatestMoviesUseCase
    @ObservationIgnored @Dependency(\.getLatestNewestMoviesUseCase) private var getLatestNewestMoviesUseCase
    @ObservationIgnored @Dependency(\.getMovieListUseCase) private var getMovieListUseCase
    @ObservationIgnored @Dependency(\.getPopularMoviesByCountryUseCase) private var getPopularMoviesByCountryUseCase
    @ObservationIgnored @Dependency(\.getPopularMoviesByGenreUseCase) private var getPopularMoviesByGenreUseCase
    @ObservationIgnored @Dependency(\.getPopularMoviesUseCase) private var getPopularMoviesUseCase
    @ObservationIgnored @Dependency(\.getPopularNewestMoviesUseCase) private var getPopularNewestMoviesUseCase
    @ObservationIgnored @Dependency(\.getSoonMoviesByCountryUseCase) private var getSoonMoviesByCountryUseCase
    @ObservationIgnored @Dependency(\.getSoonMoviesByGenreUseCase) private var getSoonMoviesByGenreUseCase
    @ObservationIgnored @Dependency(\.getSoonMoviesUseCase) private var getSoonMoviesUseCase
    @ObservationIgnored @Dependency(\.getWatchingNowMoviesByCountryUseCase) private var getWatchingNowMoviesByCountryUseCase
    @ObservationIgnored @Dependency(\.getWatchingNowMoviesByGenreUseCase) private var getWatchingNowMoviesByGenreUseCase
    @ObservationIgnored @Dependency(\.getWatchingNowMoviesUseCase) private var getWatchingNowMoviesUseCase
    @ObservationIgnored @Dependency(\.getWatchingNowNewestMoviesUseCase) private var getWatchingNowNewestMoviesUseCase
    @ObservationIgnored @Dependency(\.getLatestMoviesInCollectionUseCase) private var getLatestMoviesInCollectionUseCase
    @ObservationIgnored @Dependency(\.getSoonMoviesInCollectionUseCase) private var getSoonMoviesInCollectionUseCase
    @ObservationIgnored @Dependency(\.getPopularMoviesInCollectionUseCase) private var getPopularMoviesInCollectionUseCase
    @ObservationIgnored @Dependency(\.getWatchingNowMoviesInCollectionUseCase) private var getWatchingNowMoviesInCollectionUseCase

    @ObservationIgnored private let list: MovieList?
    @ObservationIgnored private let country: MovieCountry?
    @ObservationIgnored private let genre: MovieGenre?
    @ObservationIgnored private let category: Categories?
    @ObservationIgnored private let collection: MoviesCollection?
    @ObservationIgnored private let movies: [MovieSimple]?

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

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    private(set) var state: DataState<[MovieSimple]> = .loading
    private(set) var paginationState: DataPaginationState = .idle

    private(set) var title: String

    var filterGenre = Genres.all
    var filter = Filters.latest
    var newFilter = NewFilters.latest

    @ObservationIgnored private var page = 1

    private func getData(isInitial: Bool = true) {
        if let movies {
            withAnimation(.easeInOut) {
                self.state = .data(movies)
            }

            return
        }

        let publisher: AnyPublisher<(String?, [MovieSimple]), Error>

        if let list {
            publisher = getMovieListUseCase(listId: list.listId, page: page)
                .map { ($0.0, $0.1) }
                .eraseToAnyPublisher()
        } else if let country {
            publisher = withoutTitle(getPublisher(country: country))
        } else if let genre {
            publisher = withoutTitle(getPublisher(genre: genre))
        } else if let category {
            publisher = withoutTitle(getPublisher(category: category))
        } else if let collection {
            publisher = withoutTitle(getPublisher(collection: collection, filter: filter))
        } else {
            withAnimation(.easeInOut) {
                if isInitial {
                    self.state = .error(HDrezkaError.unknown)
                } else {
                    self.paginationState = .error(HDrezkaError.unknown)
                }
            }

            return
        }

        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self,
                      case let .failure(error) = completion
                else {
                    return
                }

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.state = .error(error)
                    } else {
                        self.paginationState = .error(error)
                    }
                }
            } receiveValue: { [weak self] title, movies in
                guard let self else { return }

                self.page += 1

                withAnimation(.easeInOut) {
                    if isInitial {
                        if let title, !title.isEmpty {
                            self.title = title
                        }
                        self.state = .data(movies)
                    } else {
                        self.state.append(movies)
                        self.paginationState = .idle
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func withoutTitle(_ publisher: AnyPublisher<[MovieSimple], Error>) -> AnyPublisher<(String?, [MovieSimple]), Error> {
        publisher
            .map { (nil, $0) }
            .eraseToAnyPublisher()
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
        subscriptions.flush()

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

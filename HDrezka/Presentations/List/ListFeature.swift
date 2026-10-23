import ComposableArchitecture
import SwiftUI

@Reducer
struct ListFeature {
    enum Source: Equatable {
        case list(MovieList)
        case country(MovieCountry)
        case genre(MovieGenre)
        case category(Categories)
        case collection(MoviesCollection)
        case movies([MovieSimple], title: String)
    }

    @ObservableState
    struct State: Equatable {
        let source: Source

        var movies: DataState<[MovieSimple]> = .loading
        var paginationState: DataPaginationState = .idle

        var title: String

        var filterGenre = Genres.all
        var filter = Filters.latest
        var newFilter = NewFilters.latest

        fileprivate var page = 1

        init(source: Source) {
            self.source = source

            let title: String? = switch source {
            case let .list(list): list.name
            case let .country(country): country.name
            case let .genre(genre): genre.name
            case let .category(category): category.localized
            case let .collection(collection): collection.name
            case let .movies(_, title): title
            }

            self.title = if let title, !title.isEmpty { title } else { String(localized: "key.list") }
        }

        var isCustomMovies: Bool {
            if case .movies = source { true } else { false }
        }

        var isList: Bool {
            if case .list = source { true } else { false }
        }

        var isCountry: Bool {
            if case .country = source { true } else { false }
        }

        var isGenre: Bool {
            if case .genre = source { true } else { false }
        }

        var isCategory: Bool {
            if case .category = source { true } else { false }
        }

        func isCategory(_ category: Categories) -> Bool {
            source == .category(category)
        }

        var isCollection: Bool {
            if case .collection = source { true } else { false }
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case reload
        case loadMore
        case moviesLoaded(isInitial: Bool, Result<(String?, [MovieSimple]), any Error>)
    }

    private enum CancelID { case load }

//    @Dependency(\.getFeaturedMoviesUseCase) private var getFeaturedMoviesUseCase
    @Dependency(\.getHotMoviesUseCase) private var getHotMoviesUseCase
    @Dependency(\.getLatestMoviesByCountryUseCase) private var getLatestMoviesByCountryUseCase
    @Dependency(\.getLatestMoviesByGenreUseCase) private var getLatestMoviesByGenreUseCase
    @Dependency(\.getLatestMoviesUseCase) private var getLatestMoviesUseCase
    @Dependency(\.getLatestNewestMoviesUseCase) private var getLatestNewestMoviesUseCase
    @Dependency(\.getMovieListUseCase) private var getMovieListUseCase
    @Dependency(\.getPopularMoviesByCountryUseCase) private var getPopularMoviesByCountryUseCase
    @Dependency(\.getPopularMoviesByGenreUseCase) private var getPopularMoviesByGenreUseCase
    @Dependency(\.getPopularMoviesUseCase) private var getPopularMoviesUseCase
    @Dependency(\.getPopularNewestMoviesUseCase) private var getPopularNewestMoviesUseCase
    @Dependency(\.getSoonMoviesByCountryUseCase) private var getSoonMoviesByCountryUseCase
    @Dependency(\.getSoonMoviesByGenreUseCase) private var getSoonMoviesByGenreUseCase
    @Dependency(\.getSoonMoviesUseCase) private var getSoonMoviesUseCase
    @Dependency(\.getWatchingNowMoviesByCountryUseCase) private var getWatchingNowMoviesByCountryUseCase
    @Dependency(\.getWatchingNowMoviesByGenreUseCase) private var getWatchingNowMoviesByGenreUseCase
    @Dependency(\.getWatchingNowMoviesUseCase) private var getWatchingNowMoviesUseCase
    @Dependency(\.getWatchingNowNewestMoviesUseCase) private var getWatchingNowNewestMoviesUseCase
    @Dependency(\.getLatestMoviesInCollectionUseCase) private var getLatestMoviesInCollectionUseCase
    @Dependency(\.getSoonMoviesInCollectionUseCase) private var getSoonMoviesInCollectionUseCase
    @Dependency(\.getPopularMoviesInCollectionUseCase) private var getPopularMoviesInCollectionUseCase
    @Dependency(\.getWatchingNowMoviesInCollectionUseCase) private var getWatchingNowMoviesInCollectionUseCase

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.filterGenre), .binding(\.filter), .binding(\.newFilter):
                return .send(.reload)

            case .binding:
                return .none

            case .onAppear:
                guard state.movies.data == nil else { return .none }

                return .send(.reload)

            case .reload:
                state.movies = .loading
                state.paginationState = .idle
                state.page = 1

                return load(state, isInitial: true)

            case .loadMore:
                guard state.paginationState == .idle, !state.isCustomMovies, !state.isCategory(.hot) else { return .none }

                state.paginationState = .loading

                return load(state, isInitial: false)

            case let .moviesLoaded(isInitial, result):
                if case let .success((title, _)) = result {
                    state.page += 1

                    if isInitial, let title, !title.isEmpty {
                        state.title = title
                    }
                }

                state.paginationState = state.movies.receivePage(result.map(\.1), isInitial: isInitial)

                return .none
            }
        }
    }

    private func load(_ state: State, isInitial: Bool) -> Effect<Action> {
        .run { [source = state.source, page = state.page, filterGenre = state.filterGenre, filter = state.filter, newFilter = state.newFilter] send in
            let result = await Result {
                try await movies(source: source, page: page, filterGenre: filterGenre, filter: filter, newFilter: newFilter)
            }

            await send(.moviesLoaded(isInitial: isInitial, result), animation: .easeInOut)
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }

    private func movies(source: Source, page: Int, filterGenre: Genres, filter: Filters, newFilter: NewFilters) async throws -> (String?, [MovieSimple]) {
        switch source {
        case let .movies(movies, _):
            return (nil, movies)
        case let .list(list):
            return try await getMovieListUseCase(listId: list.listId, page: page)
        case let .country(country):
            return try await (nil, movies(country: country, page: page, filterGenre: filterGenre, filter: filter))
        case let .genre(genre):
            return try await (nil, movies(genre: genre, page: page, filter: filter))
        case let .category(category):
            return try await (nil, movies(category: category, page: page, filterGenre: filterGenre, newFilter: newFilter))
        case let .collection(collection):
            return try await (nil, movies(collection: collection, page: page, filter: filter))
        }
    }

    private func movies(country: MovieCountry, page: Int, filterGenre: Genres, filter: Filters) async throws -> [MovieSimple] {
        switch filter {
        case .latest:
            try await getLatestMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
        case .popular:
            try await getPopularMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
        case .soon:
            try await getSoonMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
        case .watching:
            try await getWatchingNowMoviesByCountryUseCase(countryId: country.countryId, genre: filterGenre.genreCode, page: page)
        }
    }

    private func movies(genre: MovieGenre, page: Int, filter: Filters) async throws -> [MovieSimple] {
        switch filter {
        case .latest:
            try await getLatestMoviesByGenreUseCase(genreId: genre.genreId, page: page)
        case .popular:
            try await getPopularMoviesByGenreUseCase(genreId: genre.genreId, page: page)
        case .soon:
            try await getSoonMoviesByGenreUseCase(genreId: genre.genreId, page: page)
        case .watching:
            try await getWatchingNowMoviesByGenreUseCase(genreId: genre.genreId, page: page)
        }
    }

    private func movies(category: Categories, page: Int, filterGenre: Genres, newFilter: NewFilters) async throws -> [MovieSimple] {
        switch category {
        case .hot:
            try await getHotMoviesUseCase(genre: filterGenre.genreCode)
//        case .featured:
//            try await getFeaturedMoviesUseCase(page: page, genre: filterGenre.genreCode)
        case .watchingNow:
            try await getWatchingNowMoviesUseCase(page: page, genre: filterGenre.genreCode)
        case .newest:
            switch newFilter {
            case .latest:
                try await getLatestNewestMoviesUseCase(page: page, genre: filterGenre.genreCode)
            case .popular:
                try await getPopularNewestMoviesUseCase(page: page, genre: filterGenre.genreCode)
            case .watching:
                try await getWatchingNowNewestMoviesUseCase(page: page, genre: filterGenre.genreCode)
            }
        case .latest:
            try await getLatestMoviesUseCase(page: page, genre: filterGenre.genreCode)
        case .popular:
            try await getPopularMoviesUseCase(page: page, genre: filterGenre.genreCode)
        case .soon:
            try await getSoonMoviesUseCase(page: page, genre: filterGenre.genreCode)
        }
    }

    private func movies(collection: MoviesCollection, page: Int, filter: Filters) async throws -> [MovieSimple] {
        switch filter {
        case .latest:
            try await getLatestMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
        case .popular:
            try await getPopularMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
        case .soon:
            try await getSoonMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
        case .watching:
            try await getWatchingNowMoviesInCollectionUseCase(collectionId: collection.collectionId, page: page)
        }
    }
}

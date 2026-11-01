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

        var movies: DataState<[MovieSimple]> = .idle
        var pagination = Pagination()

        var title: String

        var filterGenre = Genres.all
        var filter = Filters.latest
        var newFilter = NewFilters.latest

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

    @Dependency(\.movieListsClient) private var movieListsClient
    @Dependency(\.collectionsClient) private var collectionsClient

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.filterGenre), .binding(\.filter), .binding(\.newFilter):
                return .send(.reload)

            case .binding:
                return .none

            case .onAppear:
                guard state.movies.needsLoad else { return .none }

                return .send(.reload)

            case .reload:
                state.movies = .loading
                state.pagination.reset()

                return load(state, isInitial: true)

            case .loadMore:
                guard !state.isCustomMovies, !state.isCategory(.hot), state.pagination.startLoadingMore() else { return .none }

                return load(state, isInitial: false)

            case let .moviesLoaded(isInitial, result):
                if isInitial, case let .success((title, _)) = result, let title, !title.isEmpty {
                    state.title = title
                }

                let paginationState = state.movies.receivePage(result.map(\.1), isInitial: isInitial)
                state.pagination.update(paginationState, after: result)

                return .none
            }
        }
    }

    private func load(_ state: State, isInitial: Bool) -> Effect<Action> {
        .run { [source = state.source, page = state.pagination.page, filterGenre = state.filterGenre, filter = state.filter, newFilter = state.newFilter] send in
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
            return try await movieListsClient.getMovieList(listId: list.listId, page: page)
        case let .country(country):
            return try await (nil, movieListsClient.getMoviesByCountry(countryId: country.countryId, filter: filter, genre: filterGenre.genreCode, page: page))
        case let .genre(genre):
            return try await (nil, movieListsClient.getMoviesByGenre(genreId: genre.genreId, filter: filter, page: page))
        case let .category(category):
            return try await (nil, movies(category: category, page: page, filterGenre: filterGenre, newFilter: newFilter))
        case let .collection(collection):
            return try await (nil, collectionsClient.getMoviesInCollection(collectionId: collection.collectionId, filter: filter, page: page))
        }
    }

    private func movies(category: Categories, page: Int, filterGenre: Genres, newFilter: NewFilters) async throws -> [MovieSimple] {
        switch category {
        case .hot:
            try await movieListsClient.getHotMovies(genre: filterGenre.genreCode)
//        case .featured:
//            try await movieListsClient.getFeaturedMovies(page: page, genre: filterGenre.genreCode)
        case .watchingNow:
            try await movieListsClient.getMovies(filter: .watching, genre: filterGenre.genreCode, page: page)
        case .newest:
            try await movieListsClient.getNewestMovies(filter: newFilter, genre: filterGenre.genreCode, page: page)
        case .latest:
            try await movieListsClient.getMovies(filter: .latest, genre: filterGenre.genreCode, page: page)
        case .popular:
            try await movieListsClient.getMovies(filter: .popular, genre: filterGenre.genreCode, page: page)
        case .soon:
            try await movieListsClient.getMovies(filter: .soon, genre: filterGenre.genreCode, page: page)
        }
    }
}

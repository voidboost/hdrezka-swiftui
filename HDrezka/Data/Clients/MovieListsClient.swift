import Alamofire
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct MovieListsClient: Sendable {
    var getMovies: @Sendable (_ filter: Filters, _ genre: Int, _ page: Int) async throws -> [MovieSimple]
//    var getFeaturedMovies: @Sendable (_ page: Int, _ genre: Int) async throws -> [MovieSimple]
    var getHotMovies: @Sendable (_ genre: Int) async throws -> [MovieSimple]
    var getMovieList: @Sendable (_ listId: String, _ page: Int) async throws -> (String, [MovieSimple])
    var getMoviesByCountry: @Sendable (_ countryId: String, _ filter: Filters, _ genre: Int, _ page: Int) async throws -> [MovieSimple]
    var getMoviesByGenre: @Sendable (_ genreId: String, _ filter: Filters, _ page: Int) async throws -> [MovieSimple]
    var getNewestMovies: @Sendable (_ filter: NewFilters, _ genre: Int, _ page: Int) async throws -> [MovieSimple]
}

extension MovieListsClient: DependencyKey {
    static let liveValue: Self = {
        @Dependency(\.session) var session

        return Self(
            getMovies: { filter, genre, page in
                try await session.movies(.getMovieList1(page: page, filter: filter.query, genre: genre))
            },
//            getFeaturedMovies: { page, genre in
//                try await session.movies(.getMovieList1(page: page, filter: "recommendation", genre: genre))
//            },
            getHotMovies: { genre in
                try await session.string(MovieListsService.getHotMovies(genre: genre), parse: MovieListsParser.parseHotMovies)
            },
            getMovieList: { listId, page in
                let list = listId.pathParts

                guard list.count > 1 else {
                    throw invalidInput(functionName: "getMovieList")
                }

                let type = list[0]
                let listType = list[1]
                let genre = list.count > 2 && !list[2].isNumber ? list[2] : nil
                let year = list.count > 3 ? list[3] : (list.count > 2 && list[2].isNumber ? list[2] : nil)

                return try await session.page(MovieListsService.getMovieList2(type: type, listType: listType, genre: genre, year: year, page: page), parse: MovieListsParser.parse)
            },
            getMoviesByCountry: { countryId, filter, genre, page in
                let parts = countryId.pathParts

                guard parts.count == 2 else {
                    throw invalidInput(functionName: "getMoviesByCountry")
                }

                return try await session.movies(.getMovieList4(type: parts[0], category: parts[1], page: page, genre: genre, filter: filter.query))
            },
            getMoviesByGenre: { genreId, filter, page in
                let parts = genreId.pathParts

                guard let type = parts.first else {
                    throw invalidInput(functionName: "getMoviesByGenre")
                }

                return try await session.movies(.getMovieList3(type: type, genre: parts.count > 1 ? parts[1] : nil, page: page, filter: filter.query))
            },
            getNewestMovies: { filter, genre, page in
                try await session.movies(.getNewestMovies(page: page, filter: filter.query, genre: genre))
            }
        )
    }()

    static let testValue = Self()
}

extension DependencyValues {
    var movieListsClient: MovieListsClient {
        get { self[MovieListsClient.self] }
        set { self[MovieListsClient.self] = newValue }
    }
}

private extension Session {
    func movies(_ convertible: MovieListsService) async throws -> [MovieSimple] {
        try await page(convertible, parse: MovieListsParser.parseMovies)
    }
}

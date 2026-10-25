import Alamofire
import Dependencies
import Foundation

struct MovieListsRepositoryImpl: MovieListsRepository {
    @Dependency(\.session) private var session

    private func movies(_ convertible: MovieListsService) async throws -> [MovieSimple] {
        try await session.string(convertible, parse: MovieListsParser.parseMovies)
    }

    func getMovies(filter: Filters, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await movies(.getMovieList1(page: page, filter: filter.query, genre: genre))
    }

//    func getFeaturedMovies(page: Int, genre: Int) async throws -> [MovieSimple] {
//        movies(.getMovieList1(page: page, filter: "recommendation", genre: genre))
//    }

    func getHotMovies(genre: Int) async throws -> [MovieSimple] {
        try await session.string(MovieListsService.getHotMovies(genre: genre), parse: MovieListsParser.parseHotMovies)
    }

    func getMovieList(listId: String, page: Int) async throws -> (String, [MovieSimple]) {
        let list = listId.pathParts

        guard list.count > 1 else {
            throw invalidInput()
        }

        let type = list[0]
        let listType = list[1]
        let genre = list.count > 2 && !list[2].isNumber ? list[2] : nil
        let year = list.count > 3 ? list[3] : (list.count > 2 && list[2].isNumber ? list[2] : nil)

        return try await session.string(MovieListsService.getMovieList2(type: type, listType: listType, genre: genre, year: year, page: page), parse: MovieListsParser.parse)
    }

    func getMoviesByCountry(countryId: String, filter: Filters, genre: Int, page: Int) async throws -> [MovieSimple] {
        let parts = countryId.pathParts

        guard parts.count == 2 else {
            throw invalidInput()
        }

        return try await movies(.getMovieList4(type: parts[0], category: parts[1], page: page, genre: genre, filter: filter.query))
    }

    func getMoviesByGenre(genreId: String, filter: Filters, page: Int) async throws -> [MovieSimple] {
        let parts = genreId.pathParts

        guard let type = parts.first else {
            throw invalidInput()
        }

        return try await movies(.getMovieList3(type: type, genre: parts.count > 1 ? parts[1] : nil, page: page, filter: filter.query))
    }

    func getNewestMovies(filter: NewFilters, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await movies(.getNewestMovies(page: page, filter: filter.query, genre: genre))
    }
}

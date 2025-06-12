import Alamofire
import Combine
import FactoryKit
import Foundation

struct MovieListsRepositoryImpl: MovieListsRepository {
    @Injected(\.session) private var session

    func getPopularMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(MovieListsService.getMovieList1(page: page, filter: "popular", genre: genre))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

//    func getFeaturedMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
//        session.request(MovieListsService.getMovieList1(page: page, filter: "recommendation", genre: genre))
//            .validate(statusCode: 200 ..< 400)
//            .publishString()
//            .value()
//            .tryMap(MovieListsParser.parse)
//            .map(\.1)
//            .handleError()
//            .eraseToAnyPublisher()
//    }

    func getWatchingNowMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(MovieListsService.getMovieList1(page: page, filter: "watching", genre: genre))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getLatestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(MovieListsService.getMovieList1(page: page, filter: "last", genre: genre))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getSoonMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(MovieListsService.getMovieList1(page: page, filter: "soon", genre: genre))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getHotMovies(genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(MovieListsService.getHotMovies(genre: genre))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parseHotMovies)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getMovieList(listId: String, page: Int) -> AnyPublisher<(String, [MovieSimple]), Error> {
        let list = listId.components(separatedBy: "/").filter({ !$0.isEmpty })

        guard list.count > 1 else {
            return Fail(error: HDrezkaError.null(#function, #line, #column))
                .handleError()
                .eraseToAnyPublisher()
        }

        let type = list[0]
        let listType = list[1]
        let genre = list.count > 2 && !list[2].isNumber ? list[2] : nil
        let year = list.count > 3 ? list[3] : (list.count > 2 && list[2].isNumber ? list[2] : nil)

        return session.request(MovieListsService.getMovieList2(type: type, listType: listType, genre: genre, year: year, page: page))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getPopularMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        let parts = countryId.components(separatedBy: "/").filter({ !$0.isEmpty })

        guard parts.count == 2 else {
            return Fail(error: HDrezkaError.null(#function, #line, #column))
                .handleError()
                .eraseToAnyPublisher()
        }

        let type = parts[0]
        let category = parts[1]

        return session.request(MovieListsService.getMovieList4(type: type, category: category, page: page, genre: genre, filter: "popular"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getLatestMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        let parts = countryId.components(separatedBy: "/").filter({ !$0.isEmpty })

        guard parts.count == 2 else {
            return Fail(error: HDrezkaError.null(#function, #line, #column))
                .handleError()
                .eraseToAnyPublisher()
        }

        let type = parts[0]
        let category = parts[1]

        return session.request(MovieListsService.getMovieList4(type: type, category: category, page: page, genre: genre, filter: "last"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getSoonMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        let parts = countryId.components(separatedBy: "/").filter({ !$0.isEmpty })

        guard parts.count == 2 else {
            return Fail(error: HDrezkaError.null(#function, #line, #column))
                .handleError()
                .eraseToAnyPublisher()
        }

        let type = parts[0]
        let category = parts[1]

        return session.request(MovieListsService.getMovieList4(type: type, category: category, page: page, genre: genre, filter: "soon"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getWatchingNowMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        let parts = countryId.components(separatedBy: "/").filter({ !$0.isEmpty })

        guard parts.count == 2 else {
            return Fail(error: HDrezkaError.null(#function, #line, #column))
                .handleError()
                .eraseToAnyPublisher()
        }

        let type = parts[0]
        let category = parts[1]

        return session.request(MovieListsService.getMovieList4(type: type, category: category, page: page, genre: genre, filter: "watching"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getPopularMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        let parts = genreId.components(separatedBy: "/").filter({ !$0.isEmpty })

        guard !parts.isEmpty else {
            return Fail(error: HDrezkaError.null(#function, #line, #column))
                .handleError()
                .eraseToAnyPublisher()
        }

        let type = parts[0]
        let genre = parts.count > 1 ? parts[1] : nil

        return session.request(MovieListsService.getMovieList3(type: type, genre: genre, page: page, filter: "popular"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getLatestMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        let parts = genreId.components(separatedBy: "/").filter({ !$0.isEmpty })

        guard !parts.isEmpty else {
            return Fail(error: HDrezkaError.null(#function, #line, #column))
                .handleError()
                .eraseToAnyPublisher()
        }

        let type = parts[0]
        let genre = parts.count > 1 ? parts[1] : nil

        return session.request(MovieListsService.getMovieList3(type: type, genre: genre, page: page, filter: "last"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getSoonMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        let parts = genreId.components(separatedBy: "/").filter({ !$0.isEmpty })

        guard !parts.isEmpty else {
            return Fail(error: HDrezkaError.null(#function, #line, #column))
                .handleError()
                .eraseToAnyPublisher()
        }

        let type = parts[0]
        let genre = parts.count > 1 ? parts[1] : nil

        return session.request(MovieListsService.getMovieList3(type: type, genre: genre, page: page, filter: "soon"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getWatchingNowMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        let parts = genreId.components(separatedBy: "/").filter({ !$0.isEmpty })

        guard !parts.isEmpty else {
            return Fail(error: HDrezkaError.null(#function, #line, #column))
                .handleError()
                .eraseToAnyPublisher()
        }

        let type = parts[0]
        let genre = parts.count > 1 ? parts[1] : nil

        return session.request(MovieListsService.getMovieList3(type: type, genre: genre, page: page, filter: "watching"))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getLatestNewestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(MovieListsService.getNewestMovies(page: page, filter: "last", genre: genre))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getPopularNewestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(MovieListsService.getNewestMovies(page: page, filter: "popular", genre: genre))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getWatchingNowNewestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(MovieListsService.getNewestMovies(page: page, filter: "watching", genre: genre))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }
}

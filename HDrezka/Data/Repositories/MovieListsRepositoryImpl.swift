import Alamofire
import Combine
import Dependencies
import Foundation

struct MovieListsRepositoryImpl: MovieListsRepository {
    @Dependency(\.session) private var session

    private func movies(_ convertible: MovieListsService) -> AnyPublisher<[MovieSimple], Error> {
        session.string(convertible) { try MovieListsParser.parse(from: $0).1 }
    }

    private func moviesByCountry(countryId: String, genre: Int, page: Int, filter: String, function: String = #function) -> AnyPublisher<[MovieSimple], Error> {
        let parts = countryId.pathParts

        guard parts.count == 2 else {
            return invalidInput(functionName: function)
        }

        return movies(.getMovieList4(type: parts[0], category: parts[1], page: page, genre: genre, filter: filter))
    }

    private func moviesByGenre(genreId: String, page: Int, filter: String, function: String = #function) -> AnyPublisher<[MovieSimple], Error> {
        let parts = genreId.pathParts

        guard let type = parts.first else {
            return invalidInput(functionName: function)
        }

        return movies(.getMovieList3(type: type, genre: parts.count > 1 ? parts[1] : nil, page: page, filter: filter))
    }

    func getPopularMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        movies(.getMovieList1(page: page, filter: "popular", genre: genre))
    }

//    func getFeaturedMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
//        movies(.getMovieList1(page: page, filter: "recommendation", genre: genre))
//    }

    func getWatchingNowMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        movies(.getMovieList1(page: page, filter: "watching", genre: genre))
    }

    func getLatestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        movies(.getMovieList1(page: page, filter: "last", genre: genre))
    }

    func getSoonMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        movies(.getMovieList1(page: page, filter: "soon", genre: genre))
    }

    func getHotMovies(genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.string(MovieListsService.getHotMovies(genre: genre), parse: MovieListsParser.parseHotMovies)
    }

    func getMovieList(listId: String, page: Int) -> AnyPublisher<(String, [MovieSimple]), Error> {
        let list = listId.pathParts

        guard list.count > 1 else {
            return invalidInput()
        }

        let type = list[0]
        let listType = list[1]
        let genre = list.count > 2 && !list[2].isNumber ? list[2] : nil
        let year = list.count > 3 ? list[3] : (list.count > 2 && list[2].isNumber ? list[2] : nil)

        return session.string(MovieListsService.getMovieList2(type: type, listType: listType, genre: genre, year: year, page: page), parse: MovieListsParser.parse)
    }

    func getPopularMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesByCountry(countryId: countryId, genre: genre, page: page, filter: "popular")
    }

    func getLatestMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesByCountry(countryId: countryId, genre: genre, page: page, filter: "last")
    }

    func getSoonMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesByCountry(countryId: countryId, genre: genre, page: page, filter: "soon")
    }

    func getWatchingNowMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesByCountry(countryId: countryId, genre: genre, page: page, filter: "watching")
    }

    func getPopularMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesByGenre(genreId: genreId, page: page, filter: "popular")
    }

    func getLatestMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesByGenre(genreId: genreId, page: page, filter: "last")
    }

    func getSoonMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesByGenre(genreId: genreId, page: page, filter: "soon")
    }

    func getWatchingNowMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        moviesByGenre(genreId: genreId, page: page, filter: "watching")
    }

    func getLatestNewestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        movies(.getNewestMovies(page: page, filter: "last", genre: genre))
    }

    func getPopularNewestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        movies(.getNewestMovies(page: page, filter: "popular", genre: genre))
    }

    func getWatchingNowNewestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        movies(.getNewestMovies(page: page, filter: "watching", genre: genre))
    }
}

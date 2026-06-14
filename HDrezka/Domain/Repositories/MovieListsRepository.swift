import Combine

protocol MovieListsRepository {
    func getPopularMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error>

//    func getFeaturedMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error>

    func getWatchingNowMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error>

    func getLatestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error>

    func getSoonMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error>

    func getHotMovies(genre: Int) -> AnyPublisher<[MovieSimple], Error>

    func getMovieList(listId: String, page: Int) -> AnyPublisher<(String, [MovieSimple]), Error>

    func getPopularMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getLatestMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getSoonMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getWatchingNowMoviesByCountry(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getPopularMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getLatestMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getSoonMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getWatchingNowMoviesByGenre(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getLatestNewestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error>

    func getPopularNewestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error>

    func getWatchingNowNewestMovies(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error>
}

import Dependencies

protocol MovieListsRepository: Sendable {
    func getPopularMovies(page: Int, genre: Int) async throws -> [MovieSimple]

//    func getFeaturedMovies(page: Int, genre: Int) async throws -> [MovieSimple]

    func getWatchingNowMovies(page: Int, genre: Int) async throws -> [MovieSimple]

    func getLatestMovies(page: Int, genre: Int) async throws -> [MovieSimple]

    func getSoonMovies(page: Int, genre: Int) async throws -> [MovieSimple]

    func getHotMovies(genre: Int) async throws -> [MovieSimple]

    func getMovieList(listId: String, page: Int) async throws -> (String, [MovieSimple])

    func getPopularMoviesByCountry(countryId: String, genre: Int, page: Int) async throws -> [MovieSimple]

    func getLatestMoviesByCountry(countryId: String, genre: Int, page: Int) async throws -> [MovieSimple]

    func getSoonMoviesByCountry(countryId: String, genre: Int, page: Int) async throws -> [MovieSimple]

    func getWatchingNowMoviesByCountry(countryId: String, genre: Int, page: Int) async throws -> [MovieSimple]

    func getPopularMoviesByGenre(genreId: String, page: Int) async throws -> [MovieSimple]

    func getLatestMoviesByGenre(genreId: String, page: Int) async throws -> [MovieSimple]

    func getSoonMoviesByGenre(genreId: String, page: Int) async throws -> [MovieSimple]

    func getWatchingNowMoviesByGenre(genreId: String, page: Int) async throws -> [MovieSimple]

    func getLatestNewestMovies(page: Int, genre: Int) async throws -> [MovieSimple]

    func getPopularNewestMovies(page: Int, genre: Int) async throws -> [MovieSimple]

    func getWatchingNowNewestMovies(page: Int, genre: Int) async throws -> [MovieSimple]
}

private enum MovieListsRepositoryKey: DependencyKey {
    static let liveValue: any MovieListsRepository = MovieListsRepositoryImpl()
}

extension DependencyValues {
    var movieListsRepository: any MovieListsRepository {
        get { self[MovieListsRepositoryKey.self] }
        set { self[MovieListsRepositoryKey.self] = newValue }
    }
}

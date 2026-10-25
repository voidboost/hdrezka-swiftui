import Dependencies

protocol MovieListsRepository: Sendable {
    func getMovies(filter: Filters, genre: Int, page: Int) async throws -> [MovieSimple]

//    func getFeaturedMovies(page: Int, genre: Int) async throws -> [MovieSimple]

    func getHotMovies(genre: Int) async throws -> [MovieSimple]

    func getMovieList(listId: String, page: Int) async throws -> (String, [MovieSimple])

    func getMoviesByCountry(countryId: String, filter: Filters, genre: Int, page: Int) async throws -> [MovieSimple]

    func getMoviesByGenre(genreId: String, filter: Filters, page: Int) async throws -> [MovieSimple]

    func getNewestMovies(filter: NewFilters, genre: Int, page: Int) async throws -> [MovieSimple]
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

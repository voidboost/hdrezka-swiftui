import Dependencies

protocol AccountRepository: Sendable {
    func signIn(login: String, password: String) async throws

    func signUp(email: String, login: String, password: String, verifyCode: String, step: Int) async throws

    func restore(login: String) async throws -> String?

    func logout() async throws -> Bool

    func getWatchingLaterMovies() async throws -> [MovieWatchLater]

    func saveWatchingState(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, position: Int?, total: Int?) async throws -> Bool

    func switchWatchedItem(item: MovieWatchLater) async throws -> Bool

    func removeWatchingItem(item: MovieWatchLater) async throws -> Bool

    func getSeriesUpdates() async throws -> [SeriesUpdateGroup]

    func getBookmarks() async throws -> [Bookmark]

    func getBookmarksByCategoryAdded(id: Int, genre: Int, page: Int) async throws -> [MovieSimple]

    func getBookmarksByCategoryYear(id: Int, genre: Int, page: Int) async throws -> [MovieSimple]

    func getBookmarksByCategoryPopular(id: Int, genre: Int, page: Int) async throws -> [MovieSimple]

    func createBookmarksCategory(name: String) async throws -> Bookmark

    func changeBookmarksCategoryName(id: Int, newName: String) async throws -> Bool

    func deleteBookmarksCategory(id: Int) async throws -> Bool

    func addToBookmarks(movieId: String, bookmarkUserCategory: Int) async throws -> Bool

    func removeFromBookmarks(movies: [String], bookmarkUserCategory: Int) async throws -> Bool

    func moveBetweenBookmarks(movies: [String], fromBookmarkUserCategory: Int, toBookmarkUserCategory: Int) async throws -> Int

    func reorderBookmarksCategories(newOrder: [Bookmark]) async throws -> Bool

    func getVersion() async throws -> String
}

private enum AccountRepositoryKey: DependencyKey {
    static let liveValue: any AccountRepository = AccountRepositoryImpl()
}

extension DependencyValues {
    var accountRepository: any AccountRepository {
        get { self[AccountRepositoryKey.self] }
        set { self[AccountRepositoryKey.self] = newValue }
    }
}

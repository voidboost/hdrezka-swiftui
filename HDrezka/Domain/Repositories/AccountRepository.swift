import Combine

protocol AccountRepository {
    func signIn(login: String, password: String) -> AnyPublisher<Bool, Error>

    func signUp(email: String, login: String, password: String) -> AnyPublisher<Bool, Error>

    func restore(login: String) -> AnyPublisher<String?, Error>

    func logout()

    func checkEmail(email: String) -> AnyPublisher<Bool, Error>

    func checkUsername(username: String) -> AnyPublisher<Bool, Error>

    func getWatchingLaterMovies() -> AnyPublisher<[MovieWatchLater], Error>

    func saveWatchingState(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, position: Int, total: Int) -> AnyPublisher<Bool, Error>

    func switchWatchedItem(item: MovieWatchLater) -> AnyPublisher<Bool, Error>

    func removeWatchingItem(item: MovieWatchLater) -> AnyPublisher<Bool, Error>

    func getSeriesUpdates() -> AnyPublisher<[SeriesUpdateGroup], Error>

    func getBookmarks() -> AnyPublisher<[Bookmark], Error>

    func getBookmarksByCategoryAdded(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getBookmarksByCategoryYear(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func getBookmarksByCategoryPopular(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error>

    func createBookmarksCategory(name: String) -> AnyPublisher<Bookmark, Error>

    func changeBookmarksCategoryName(id: Int, newName: String) -> AnyPublisher<Bool, Error>

    func deleteBookmarksCategory(id: Int) -> AnyPublisher<Bool, Error>

    func addToBookmarks(movieId: String, bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error>

    func removeFromBookmarks(movies: [String], bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error>

    func moveBetweenBookmarks(movies: [String], fromBookmarkUserCategory: Int, toBookmarkUserCategory: Int) -> AnyPublisher<Int, Error>

    func reorderBookmarksCategories(newOrder: [Bookmark]) -> AnyPublisher<Bool, Error>

    func getVersion() -> AnyPublisher<String, Error>
}

import Dependencies

protocol MovieDetailsRepository: Sendable {
    func getMovieDetails(movieId: String) async throws -> MovieDetailed

    func getMovieBookmarks(movieId: String) async throws -> [Bookmark]

    func getMovieVideo(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, favs: String) async throws -> MovieVideo

    func getMovieThumbnails(path: String) async throws -> WebVTT

    func getSeriesSeasons(movieId: String, voiceActing: MovieVoiceActing, favs: String) async throws -> [MovieSeason]

    func getMovieTrailerId(movieId: String) async throws -> String

    func getCommentsPage(movieId: String, page: Int) async throws -> [Comment]

    func getComment(movieId: String, commentId: String) async throws -> Comment

    func toggleLikeComment(id: String) async throws -> (Int, Bool)

    func reportComment(id: String, issue: Int, text: String) async throws

    func deleteComment(id: String, hash: String) async throws

    func sendComment(id: String?, postId: String, name: String?, text: String, adb: String?, type: String?) async throws -> SendCommentResult

    func getLikes(id: String) async throws -> [Like]

    func rate(id: String, rating: Int) async throws -> (Float?, String?)?
}

private enum MovieDetailsRepositoryKey: DependencyKey {
    static let liveValue: any MovieDetailsRepository = MovieDetailsRepositoryImpl()
}

extension DependencyValues {
    var movieDetailsRepository: any MovieDetailsRepository {
        get { self[MovieDetailsRepositoryKey.self] }
        set { self[MovieDetailsRepositoryKey.self] = newValue }
    }
}

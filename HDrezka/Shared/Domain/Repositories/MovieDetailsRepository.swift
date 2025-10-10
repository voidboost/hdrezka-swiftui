import Combine

protocol MovieDetailsRepository {
    func getMovieDetails(movieId: String) -> AnyPublisher<MovieDetailed, Error>

    func getMovieBookmarks(movieId: String) -> AnyPublisher<[Bookmark], Error>

    func getMovieVideo(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, favs: String) -> AnyPublisher<MovieVideo, Error>

    func getMovieThumbnails(path: String) -> AnyPublisher<WebVTT, Error>

    func getSeriesSeasons(movieId: String, voiceActing: MovieVoiceActing, favs: String) -> AnyPublisher<[MovieSeason], Error>

    func getMovieTrailerId(movieId: String) -> AnyPublisher<String, Error>

    func getCommentsPage(movieId: String, page: Int) -> AnyPublisher<[Comment], Error>

    func getComment(movieId: String, commentId: String) -> AnyPublisher<Comment, Error>

    func toggleLikeComment(id: String) -> AnyPublisher<(Int, Bool), Error>

    func reportComment(id: String, issue: Int, text: String) -> AnyPublisher<Bool, Error>

    func deleteComment(id: String, hash: String) -> AnyPublisher<(Bool, String?), Error>

    func sendComment(id: String?, postId: String, name: String?, text: String, adb: String?, type: String?) -> AnyPublisher<SendCommentResult, Error>

    func getLikes(id: String) -> AnyPublisher<[Like], Error>

    func rate(id: String, rating: Int) -> AnyPublisher<(Float?, String?)?, Error>
}

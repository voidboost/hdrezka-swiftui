import Alamofire
import Combine
import Dependencies
import Foundation

struct MovieDetailsRepositoryImpl: MovieDetailsRepository {
    @Dependency(\.session) private var session

    private func movieDetailsPage<T>(movieId: String, function: String = #function, parse: @escaping (String) throws -> T) -> AnyPublisher<T, Error> {
        let parts = movieId.pathParts

        guard parts.count == 3 else {
            return invalidInput(functionName: function)
        }

        return session.string(MovieDetailsService.getMovieDetails(type: parts[0], genre: parts[1], name: parts[2]), parse: parse)
    }

    func getMovieDetails(movieId: String) -> AnyPublisher<MovieDetailed, Error> {
        movieDetailsPage(movieId: movieId) { res in
            try MovieDetailsParser.parseMovieDetails(from: res, movieId: movieId)
        }
    }

    func getMovieBookmarks(movieId: String) -> AnyPublisher<[Bookmark], Error> {
        movieDetailsPage(movieId: movieId, parse: MovieDetailsParser.parseBookmarks)
    }

    func getMovieVideo(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, favs: String) -> AnyPublisher<MovieVideo, Error> {
        session.string(MovieDetailsService.getMovieVideo(voiceActing: voiceActing, season: season, episode: episode, favs: favs), parse: MovieDetailsParser.parseMovieVideo)
    }

    func getMovieThumbnails(path: String) -> AnyPublisher<WebVTT, Error> {
        session.request(MovieDetailsService.getMovieThumbnails(path: path))
            .validate(statusCode: 200 ..< 400)
            .publishString(queue: parsingQueue)
            .tryMap { res in
                guard let url = res.request?.url,
                      let string = res.value
                else {
                    throw HDrezkaError.parseJson("getMovieThumbnails", "url or string")
                }

                return try WebVTTParser(string: string, vttUrl: url).parse()
            }
            .receive(on: DispatchQueue.main)
            .handleError()
    }

    func getSeriesSeasons(movieId: String, voiceActing: MovieVoiceActing, favs: String) -> AnyPublisher<[MovieSeason], Error> {
        session.string(MovieDetailsService.getSeriesSeasons(movieId: movieId, voiceActing: voiceActing, favs: favs), parse: MovieDetailsParser.parseSeriesSeasons)
    }

    func getMovieTrailerId(movieId: String) -> AnyPublisher<String, Error> {
        session.string(MovieDetailsService.getMovieTrailer(id: movieId), parse: MovieDetailsParser.parseTrailerId)
    }

    func getCommentsPage(movieId: String, page: Int) -> AnyPublisher<[Comment], Error> {
        session.string(MovieDetailsService.getComments(movieId: movieId, page: page, type: nil, commentId: nil, skin: nil), parse: MovieDetailsParser.parseComments)
    }

    func getComment(movieId: String, commentId: String) -> AnyPublisher<Comment, Error> {
        session.string(MovieDetailsService.getComments(movieId: movieId, page: nil, type: nil, commentId: commentId, skin: nil)) { res in
            try MovieDetailsParser.parseComments(from: res).lazy.compactMap { $0.findComment(commentId) }.first.orThrow()
        }
    }

    func toggleLikeComment(id: String) -> AnyPublisher<(Int, Bool), Error> {
        session.json(MovieDetailsService.toggleCommentLike(id: id), function: "toggleLikeComment") { json in
            let count: Int = try json.require("count")
            let type: String = try json.require("type")

            return (count, type == "plus")
        }
    }

    func reportComment(id: String, issue: Int, text: String) -> AnyPublisher<Bool, Error> {
        session.success(MovieDetailsService.reportComment(id: id, issue: issue, text: text), function: "reportComment")
    }

    func deleteComment(id: String, hash: String) -> AnyPublisher<(Bool, String?), Error> {
        session.json(MovieDetailsService.deleteComment(id: id, hash: hash), function: "deleteComment") { json in
            try (json.require("success"), json["message"])
        }
    }

    func sendComment(id: String?, postId: String, name: String?, text: String, adb: String?, type: String?) -> AnyPublisher<SendCommentResult, Error> {
        session.json(MovieDetailsService.sendComment(id: id, postId: postId, name: name, text: text, adb: adb, type: type), function: "sendComment") { json in
            let success: Bool = try json.require("success")
            let onModeration: Bool = try json.require("on_moderation")
            let message: [String] = try json.require("message")

            return SendCommentResult(success: success, onModeration: onModeration, message: message.joined(separator: "\n"))
        }
    }

    func getLikes(id: String) -> AnyPublisher<[Like], Error> {
        session.json(MovieDetailsService.getlikes(id: id), function: "getLikes") { json in
            try MovieDetailsParser.parseLikes(from: json.require("message"))
        }
    }

    func rate(id: String, rating: Int) -> AnyPublisher<(Float?, String?)?, Error> {
        session.json(MovieDetailsService.rate(id: id, rating: rating), function: "rate") { json in
            let success: Bool = try json.require("success")

            guard success else {
                return nil
            }

            let num: String? = json["num"]
            let votes: String? = json["votes"]

            return (Float(num ?? ""), votes?.shortNumber)
        }
    }
}

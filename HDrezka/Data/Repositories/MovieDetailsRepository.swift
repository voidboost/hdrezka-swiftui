import Alamofire
import Combine
import Foundation
import OrderedCollections

protocol MovieDetailsRepository {
    func getMovieDetails(movieId: String) -> AnyPublisher<MovieDetailed, Error>

    func getBookmarks(movieId: String) -> AnyPublisher<[Bookmark], Error>

    func getMovieVideo(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, favs: String) -> AnyPublisher<MovieVideo, Error>

    func getMovieThumbnails(path: String) -> AnyPublisher<WebVTT, Error>

    func getSeriesSeasons(movieId: String, voiceActing: MovieVoiceActing, favs: String) -> AnyPublisher<[MovieSeason], Error>

    func getMovieTrailerId(movieId: String) -> AnyPublisher<String, Error>

    func getCommentsPage(movieId: String, page: Int) -> AnyPublisher<[Comment], Error>

    func getComment(movieId: String, commentId: String) -> AnyPublisher<Comment, Error>

    func toggleLikeComment(id: String) -> AnyPublisher<(Int, Bool), Error>

    func reportComment(id: String, issue: Int, text: String) -> AnyPublisher<Bool, Error>

    func deleteComment(id: String, hash: String) -> AnyPublisher<(Bool, String?), Error>

    func sendComment(id: String?, postId: String, name: String?, text: String, adb: String?, type: String?) -> AnyPublisher<(Bool, Bool, String), Error>

    func getLikes(id: String) -> AnyPublisher<[Like], Error>

    func rate(id: String, rating: Int) -> AnyPublisher<(Float?, String?)?, Error>
}

struct MovieDetailsRepositoryImpl: MovieDetailsRepository {
    func getMovieDetails(movieId: String) -> AnyPublisher<MovieDetailed, Error> {
        let parts = movieId.components(separatedBy: "/")

        guard parts.count == 3 else {
            return Fail(error: HDrezkaError.null(#function, #line, #column))
                .handleError()
                .eraseToAnyPublisher()
        }

        let type = parts[0]
        let genre = parts[1]
        let name = parts[2]

        return Const.session.request(MovieDetailsService.getMovieDetails(type: type, genre: genre, name: name))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap { res in
                try MovieDetailsParser.parseMovieDetails(from: res, movieId: movieId)
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func getBookmarks(movieId: String) -> AnyPublisher<[Bookmark], Error> {
        let parts = movieId.components(separatedBy: "/")

        guard parts.count == 3 else {
            return Fail(error: HDrezkaError.null(#function, #line, #column))
                .handleError()
                .eraseToAnyPublisher()
        }

        let type = parts[0]
        let genre = parts[1]
        let name = parts[2]

        return Const.session.request(MovieDetailsService.getMovieDetails(type: type, genre: genre, name: name))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieDetailsParser.parseBookmarks)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getMovieVideo(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, favs: String) -> AnyPublisher<MovieVideo, Error> {
        Const.session.request(MovieDetailsService.getMovieVideo(voiceActing: voiceActing, season: season, episode: episode, favs: favs))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieDetailsParser.parseMovieVideo)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getMovieThumbnails(path: String) -> AnyPublisher<WebVTT, Error> {
        Const.session.request(MovieDetailsService.getMovieThumbnails(path: path))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .tryMap { res in
                guard let url = res.request?.url,
                      let string = res.value
                else {
                    throw HDrezkaError.parseJson("getMovieThumbnails", "url or string")
                }

                return try WebVTTParser(string: string, vttUrl: url).parse()
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func getSeriesSeasons(movieId: String, voiceActing: MovieVoiceActing, favs: String) -> AnyPublisher<[MovieSeason], Error> {
        Const.session.request(MovieDetailsService.getSeriesSeasons(movieId: movieId, voiceActing: voiceActing, favs: favs))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieDetailsParser.parseSeriesSeasons)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getMovieTrailerId(movieId: String) -> AnyPublisher<String, Error> {
        Const.session.request(MovieDetailsService.getMovieTrailer(id: movieId))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieDetailsParser.parseTrailerId)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getCommentsPage(movieId: String, page: Int) -> AnyPublisher<[Comment], Error> {
        Const.session.request(MovieDetailsService.getComments(movieId: movieId, page: page, type: nil, commentId: nil, skin: nil))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieDetailsParser.parseComments)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getComment(movieId: String, commentId: String) -> AnyPublisher<Comment, Error> {
        Const.session.request(MovieDetailsService.getComments(movieId: movieId, page: nil, type: nil, commentId: commentId, skin: nil))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieDetailsParser.parseComments)
            .tryMap { try $0.compactMap { $0.findComment(commentId) }.first.orThrow() }
            .handleError()
            .eraseToAnyPublisher()
    }

    func toggleLikeComment(id: String) -> AnyPublisher<(Int, Bool), Error> {
        Const.session.request(MovieDetailsService.toggleCommentLike(id: id))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let count = json["count"] as? Int,
                      let type = json["type"] as? String
                else {
                    throw HDrezkaError.parseJson("count or type", "toggleLikeComment")
                }

                return (count, type == "plus")
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func reportComment(id: String, issue: Int, text: String) -> AnyPublisher<Bool, Error> {
        Const.session.request(MovieDetailsService.reportComment(id: id, issue: issue, text: text))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool
                else {
                    throw HDrezkaError.parseJson("success", "reportComment")
                }

                return success
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func deleteComment(id: String, hash: String) -> AnyPublisher<(Bool, String?), Error> {
        Const.session.request(MovieDetailsService.deleteComment(id: id, hash: hash))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool
                else {
                    throw HDrezkaError.parseJson("success", "reportComment")
                }

                return (success, json["message"] as? String)
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func sendComment(id: String?, postId: String, name: String?, text: String, adb: String?, type: String?) -> AnyPublisher<(Bool, Bool, String), Error> {
        Const.session.request(MovieDetailsService.sendComment(id: id, postId: postId, name: name, text: text, adb: adb, type: type))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool,
                      let onModeration = json["on_moderation"] as? Bool,
                      let message = json["message"] as? [String]
                else {
                    throw HDrezkaError.parseJson("success or on_moderation or message", "sendComment")
                }

                return (success, onModeration, message.joined(separator: "\n"))
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func getLikes(id: String) -> AnyPublisher<[Like], Error> {
        Const.session.request(MovieDetailsService.getlikes(id: id))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let message = json["message"] as? String
                else {
                    throw HDrezkaError.parseJson("message", "getLikes")
                }

                return try MovieDetailsParser.parseLikes(from: message)
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func rate(id: String, rating: Int) -> AnyPublisher<(Float?, String?)?, Error> {
        Const.session.request(MovieDetailsService.rate(id: id, rating: rating))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool
                else {
                    throw HDrezkaError.parseJson("success", "rate")
                }

                if success {
                    let num = json["num"] as? String
                    let votes = json["votes"] as? String

                    return (Float(num ?? ""), votes?.shortNumber)
                } else {
                    return nil
                }
            }
            .handleError()
            .eraseToAnyPublisher()
    }
}

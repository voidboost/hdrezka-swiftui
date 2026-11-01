import Alamofire
import Dependencies
import DependenciesMacros
import Foundation
import SwiftSoup

@DependencyClient
struct MovieDetailsClient: Sendable {
    var getMovieDetails: @Sendable (_ movieId: String) async throws -> MovieDetailed
    var getMovieBookmarks: @Sendable (_ movieId: String) async throws -> [Bookmark]
    var getMovieVideo: @Sendable (_ voiceActing: MovieVoiceActing, _ season: MovieSeason?, _ episode: MovieEpisode?, _ favs: String) async throws -> MovieVideo
    var getMovieThumbnails: @Sendable (_ path: String) async throws -> WebVTT
    var getSeriesSeasons: @Sendable (_ movieId: String, _ voiceActing: MovieVoiceActing, _ favs: String) async throws -> [MovieSeason]
    var getMovieTrailerId: @Sendable (_ movieId: String) async throws -> String
    var getCommentsPage: @Sendable (_ movieId: String, _ page: Int) async throws -> [Comment]
    var getComment: @Sendable (_ movieId: String, _ commentId: String) async throws -> Comment
    var toggleLikeComment: @Sendable (_ id: String) async throws -> (Int, Bool)
    var reportComment: @Sendable (_ id: String, _ issue: Int, _ text: String) async throws -> Void
    var deleteComment: @Sendable (_ id: String, _ hash: String) async throws -> Void
    var sendComment: @Sendable (_ id: String?, _ postId: String, _ name: String?, _ text: String, _ adb: String?, _ type: String?) async throws -> SendCommentResult
    var getLikes: @Sendable (_ id: String) async throws -> [Like]
    var rate: @Sendable (_ id: String, _ rating: Int) async throws -> (Float?, String?)?
}

extension MovieDetailsClient: DependencyKey {
    static let liveValue: Self = {
        @Dependency(\.session) var session

        return Self(
            getMovieDetails: { movieId in
                try await session.movieDetailsPage(movieId: movieId, function: "getMovieDetails") { res in
                    try MovieDetailsParser.parseMovieDetails(from: res, movieId: movieId)
                }
            },
            getMovieBookmarks: { movieId in
                try await session.movieDetailsPage(movieId: movieId, function: "getMovieBookmarks", parse: MovieDetailsParser.parseBookmarks)
            },
            getMovieVideo: { voiceActing, season, episode, favs in
                try await session.string(MovieDetailsService.getMovieVideo(voiceActing: voiceActing, season: season, episode: episode, favs: favs), parse: MovieDetailsParser.parseMovieVideo)
            },
            getMovieThumbnails: { path in
                try await handlingErrors {
                    let response = await session.request(MovieDetailsService.getMovieThumbnails(path: path))
                        .validate(statusCode: 200 ..< 400)
                        .serializingString()
                        .response

                    let string = try response.result.get()

                    guard let url = response.request?.url else {
                        throw HDrezkaError.parseJson("getMovieThumbnails", "url or string")
                    }

                    return try WebVTTParser(string: string, vttUrl: url).parse()
                }
            },
            getSeriesSeasons: { movieId, voiceActing, favs in
                try await session.string(MovieDetailsService.getSeriesSeasons(movieId: movieId, voiceActing: voiceActing, favs: favs), parse: MovieDetailsParser.parseSeriesSeasons)
            },
            getMovieTrailerId: { movieId in
                try await session.json(MovieDetailsService.getMovieTrailer(id: movieId), function: "getMovieTrailerId") { json in
                    try MovieDetailsParser.parseTrailerId(code: json.require("code"))
                }
            },
            getCommentsPage: { movieId, page in
                try await session.json(MovieDetailsService.getComments(movieId: movieId, page: page, type: nil, commentId: nil, skin: nil), function: "getCommentsPage") { json in
                    try MovieDetailsParser.parseComments(html: json["comments"])
                }
            },
            getComment: { movieId, commentId in
                try await session.json(MovieDetailsService.getComments(movieId: movieId, page: nil, type: nil, commentId: commentId, skin: nil), function: "getComment") { json in
                    try MovieDetailsParser.parseComments(html: json["comments"]).lazy.compactMap { $0.findComment(commentId) }.first.orThrow()
                }
            },
            toggleLikeComment: { id in
                try await session.json(MovieDetailsService.toggleCommentLike(id: id), function: "toggleLikeComment") { json in
                    let count: Int = try json.require("count")
                    let type: String = try json.require("type")

                    return (count, type == "plus")
                }
            },
            reportComment: { id, issue, text in
                try await session.success(MovieDetailsService.reportComment(id: id, issue: issue, text: text), function: "reportComment")
            },
            deleteComment: { id, hash in
                try await session.success(MovieDetailsService.deleteComment(id: id, hash: hash), function: "deleteComment")
            },
            sendComment: { id, postId, name, text, adb, type in
                try await session.json(MovieDetailsService.sendComment(id: id, postId: postId, name: name, text: text, adb: adb, type: type), function: "sendComment") { json in
                    let success: Bool = try json.require("success")
                    let onModeration: Bool = try json.require("on_moderation")
                    let message: [String] = try json.require("message")

                    return SendCommentResult(success: success, onModeration: onModeration, message: message.joined(separator: "\n"))
                }
            },
            getLikes: { id in
                try await session.json(MovieDetailsService.getlikes(id: id), function: "getLikes") { json in
                    try MovieDetailsParser.parseLikes(from: json.require("message"))
                }
            },
            rate: { id, rating in
                try await session.json(MovieDetailsService.rate(id: id, rating: rating), function: "rate") { json in
                    let success: Bool = try json.require("success")

                    guard success else {
                        return nil
                    }

                    let num: String? = json["num"]
                    let votes: String? = json["votes"]

                    return (Float(num ?? ""), votes?.shortNumber)
                }
            }
        )
    }()

    static let testValue = Self()
}

extension DependencyValues {
    var movieDetailsClient: MovieDetailsClient {
        get { self[MovieDetailsClient.self] }
        set { self[MovieDetailsClient.self] = newValue }
    }
}

private extension Session {
    func movieDetailsPage<T>(movieId: String, function: String, parse: (Document) throws -> T) async throws -> T {
        let parts = movieId.pathParts

        guard parts.count == 3 else {
            throw invalidInput(functionName: function)
        }

        return try await page(MovieDetailsService.getMovieDetails(type: parts[0], genre: parts[1], name: parts[2]), parse: parse)
    }
}

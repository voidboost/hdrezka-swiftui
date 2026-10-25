import Alamofire
import Dependencies
import Foundation
import SwiftSoup

struct MovieDetailsRepositoryImpl: MovieDetailsRepository {
    @Dependency(\.session) private var session

    private func movieDetailsPage<T>(movieId: String, function: String = #function, parse: (Document) throws -> T) async throws -> T {
        let parts = movieId.pathParts

        guard parts.count == 3 else {
            throw invalidInput(functionName: function)
        }

        return try await session.page(MovieDetailsService.getMovieDetails(type: parts[0], genre: parts[1], name: parts[2]), parse: parse)
    }

    func getMovieDetails(movieId: String) async throws -> MovieDetailed {
        try await movieDetailsPage(movieId: movieId) { res in
            try MovieDetailsParser.parseMovieDetails(from: res, movieId: movieId)
        }
    }

    func getMovieBookmarks(movieId: String) async throws -> [Bookmark] {
        try await movieDetailsPage(movieId: movieId, parse: MovieDetailsParser.parseBookmarks)
    }

    func getMovieVideo(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, favs: String) async throws -> MovieVideo {
        try await session.string(MovieDetailsService.getMovieVideo(voiceActing: voiceActing, season: season, episode: episode, favs: favs), parse: MovieDetailsParser.parseMovieVideo)
    }

    @concurrent
    func getMovieThumbnails(path: String) async throws -> WebVTT {
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
    }

    func getSeriesSeasons(movieId: String, voiceActing: MovieVoiceActing, favs: String) async throws -> [MovieSeason] {
        try await session.string(MovieDetailsService.getSeriesSeasons(movieId: movieId, voiceActing: voiceActing, favs: favs), parse: MovieDetailsParser.parseSeriesSeasons)
    }

    func getMovieTrailerId(movieId: String) async throws -> String {
        try await session.json(MovieDetailsService.getMovieTrailer(id: movieId), function: "getMovieTrailerId") { json in
            try MovieDetailsParser.parseTrailerId(code: json.require("code"))
        }
    }

    func getCommentsPage(movieId: String, page: Int) async throws -> [Comment] {
        try await session.json(MovieDetailsService.getComments(movieId: movieId, page: page, type: nil, commentId: nil, skin: nil), function: "getCommentsPage") { json in
            try MovieDetailsParser.parseComments(html: json["comments"])
        }
    }

    func getComment(movieId: String, commentId: String) async throws -> Comment {
        try await session.json(MovieDetailsService.getComments(movieId: movieId, page: nil, type: nil, commentId: commentId, skin: nil), function: "getComment") { json in
            try MovieDetailsParser.parseComments(html: json["comments"]).lazy.compactMap { $0.findComment(commentId) }.first.orThrow()
        }
    }

    func toggleLikeComment(id: String) async throws -> (Int, Bool) {
        try await session.json(MovieDetailsService.toggleCommentLike(id: id), function: "toggleLikeComment") { json in
            let count: Int = try json.require("count")
            let type: String = try json.require("type")

            return (count, type == "plus")
        }
    }

    func reportComment(id: String, issue: Int, text: String) async throws {
        try await session.success(MovieDetailsService.reportComment(id: id, issue: issue, text: text), function: "reportComment")
    }

    func deleteComment(id: String, hash: String) async throws {
        try await session.success(MovieDetailsService.deleteComment(id: id, hash: hash), function: "deleteComment")
    }

    func sendComment(id: String?, postId: String, name: String?, text: String, adb: String?, type: String?) async throws -> SendCommentResult {
        try await session.json(MovieDetailsService.sendComment(id: id, postId: postId, name: name, text: text, adb: adb, type: type), function: "sendComment") { json in
            let success: Bool = try json.require("success")
            let onModeration: Bool = try json.require("on_moderation")
            let message: [String] = try json.require("message")

            return SendCommentResult(success: success, onModeration: onModeration, message: message.joined(separator: "\n"))
        }
    }

    func getLikes(id: String) async throws -> [Like] {
        try await session.json(MovieDetailsService.getlikes(id: id), function: "getLikes") { json in
            try MovieDetailsParser.parseLikes(from: json.require("message"))
        }
    }

    func rate(id: String, rating: Int) async throws -> (Float?, String?)? {
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
}

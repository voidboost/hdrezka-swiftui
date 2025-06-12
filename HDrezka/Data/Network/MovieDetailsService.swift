import Alamofire
import Defaults
import Foundation

enum MovieDetailsService {
    case getMovieDetails(type: String, genre: String, name: String)
    case getMovieTrailer(id: String)
    case getMovieVideo(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, favs: String)
    case getMovieThumbnails(path: String)
    case getSeriesSeasons(movieId: String, voiceActing: MovieVoiceActing, favs: String)
    case getComments(
        movieId: String,
        page: Int?,
        type: Int?,
        commentId: String?,
        skin: String?,
    )
    case toggleCommentLike(id: String)
    case reportComment(id: String, issue: Int, text: String)
    case deleteComment(id: String, hash: String)
    case sendComment(id: String?, postId: String, name: String?, text: String, adb: String?, type: String?)
    case getlikes(id: String)
    case rate(id: String, rating: Int)
}

extension MovieDetailsService: URLRequestConvertible {
    var baseURL: URL { Defaults[.mirror] }

    var path: String {
        switch self {
        case let .getMovieDetails(type, genre, name):
            "\(type)/\(genre)/\(name)"
        case .getMovieTrailer:
            "engine/ajax/gettrailervideo.php"
        case let .getSeriesSeasons(_, voiceActing, _):
            if let path = voiceActing.url {
                path
            } else {
                "ajax/get_cdn_series/"
            }
        case let .getMovieVideo(voiceActing, _, episode, _):
            if let path = episode?.url ?? voiceActing.url {
                path
            } else {
                "ajax/get_cdn_series/"
            }
        case let .getMovieThumbnails(path):
            String(path.reversed().drop(while: { $0 != "/" }).reversed().dropFirst())
        case .getComments:
            "ajax/get_comments/"
        case .toggleCommentLike:
            "engine/ajax/comments_like.php"
        case .reportComment:
            "engine/ajax/complaint.php"
        case .deleteComment:
            "engine/ajax/deletecomments.php"
        case .sendComment:
            "ajax/add_comment/"
        case .getlikes:
            "ajax/comments_likes/"
        case .rate:
            "engine/ajax/rating.php"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getMovieTrailer, .toggleCommentLike, .reportComment, .sendComment, .getlikes, .rate:
            .post
        case let .getMovieVideo(voiceActing, _, episode, _):
            if episode?.url == nil, voiceActing.url == nil {
                .post
            } else {
                .get
            }
        case let .getSeriesSeasons(_, voiceActing, _):
            if voiceActing.url == nil {
                .post
            } else {
                .get
            }
        default:
            .get
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appending(path: path, directoryHint: .notDirectory)

        var request = URLRequest(url: url)
        request.method = method
        request.headers = Const.headers

        switch self {
        case let .getMovieTrailer(id):
            return try URLEncoding.httpBody.encode(request, with: ["id": id])
        case let .getMovieVideo(voiceActing, season, episode, favs):
            guard episode?.url == nil, voiceActing.url == nil else {
                return request
            }

            var params: [String: Any] = [:]
            params["id"] = voiceActing.voiceId
            params["translator_id"] = voiceActing.translatorId
            params["favs"] = favs

            if !voiceActing.isCamrip.isEmpty {
                params["is_camrip"] = voiceActing.isCamrip
            }
            if !voiceActing.isAds.isEmpty {
                params["is_ads"] = voiceActing.isAds
            }
            if !voiceActing.isDirector.isEmpty {
                params["is_director"] = voiceActing.isDirector
            }

            if let season, let episode {
                params["season"] = season.seasonId
                params["episode"] = episode.episodeId
                params["action"] = "get_stream"
            } else {
                params["action"] = "get_movie"
            }

            return try URLEncoding.httpBody.encode(URLEncoding.queryString.encode(request, with: ["t": Int(Date().timeIntervalSince1970 * 1000)]), with: params)
        case .getMovieThumbnails:
            return try URLEncoding.queryString.encode(request, with: ["t": Int(Date().timeIntervalSince1970 * 1000)])
        case let .getSeriesSeasons(movieId, voiceActing, favs):
            guard voiceActing.url == nil else {
                return request
            }

            return try URLEncoding.httpBody.encode(URLEncoding.queryString.encode(request, with: ["t": Int(Date().timeIntervalSince1970 * 1000)]), with: ["id": movieId, "translator_id": voiceActing.translatorId, "action": "get_episodes", "favs": favs])
        case let .getComments(movieId, page, type, commentId, skin):
            var params: [String: Any] = [:]
            params["news_id"] = movieId
            params["cstart"] = page ?? 1
            params["t"] = Int(Date().timeIntervalSince1970 * 1000)
            params["type"] = type ?? 0
            params["comment_id"] = commentId ?? 0
            params["skin"] = skin ?? "hdrezka"

            return try URLEncoding.queryString.encode(request, with: params)
        case let .toggleCommentLike(id):
            return try URLEncoding.httpBody.encode(request, with: ["id": id])
        case let .reportComment(id, issue, text):
            return try URLEncoding.httpBody.encode(request, with: ["id": id, "issue_id": issue, "text": text, "action": "comments"])
        case let .deleteComment(id, hash):
            return try URLEncoding.queryString.encode(request, with: ["id": id, "dle_allow_hash": hash, "type": 0, "area": "ajax"])
        case let .sendComment(id, postId, name, text, adb, type):
            var params: [String: Any] = [:]
            params["parent"] = id ?? 0
            params["replyto_id"] = id
            params["post_id"] = postId
            params["name"] = name
            params["comments"] = text
            params["type"] = type
            params["has_adb"] = adb ?? 1
            params["g_recaptcha_response"] = ""

            return try URLEncoding.httpBody.encode(request, with: params)
        case let .getlikes(id):
            return try URLEncoding.httpBody.encode(request, with: ["comment_id": id])
        case let .rate(id, rating):
            return try URLEncoding.httpBody.encode(request, with: ["news_id": id, "go_rate": rating, "skin": "hdrezka"])
        default:
            return request
        }
    }
}

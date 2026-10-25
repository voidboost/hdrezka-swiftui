import Alamofire
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

extension MovieDetailsService: Endpoint {
    private var directPath: String? {
        switch self {
        case let .getMovieVideo(voiceActing, _, episode, _):
            episode?.url ?? voiceActing.url
        case let .getSeriesSeasons(_, voiceActing, _):
            voiceActing.url
        default:
            nil
        }
    }

    var path: String {
        switch self {
        case let .getMovieDetails(type, genre, name):
            "\(type)/\(genre)/\(name)"
        case .getMovieTrailer:
            "engine/ajax/gettrailervideo.php"
        case .getSeriesSeasons, .getMovieVideo:
            directPath ?? "ajax/get_cdn_series/"
        case let .getMovieThumbnails(path):
            path.substringBeforeLast("/", includeSeparator: true).substringAfter("/")
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
        case .getMovieVideo, .getSeriesSeasons:
            directPath == nil ? .post : .get
        default:
            .get
        }
    }

    func encode(_ request: URLRequest) throws -> URLRequest {
        switch self {
        case let .getMovieTrailer(id):
            return try request.body(["id": id])
        case let .getMovieVideo(voiceActing, season, episode, favs):
            guard directPath == nil else {
                return request
            }

            var params: Parameters = ["id": voiceActing.voiceId, "translator_id": voiceActing.translatorId, "favs": favs]

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

            return try request.timestamped().body(params)
        case .getMovieThumbnails:
            return try request.timestamped()
        case let .getSeriesSeasons(movieId, voiceActing, favs):
            guard directPath == nil else {
                return request
            }

            return try request.timestamped().body(["id": movieId, "translator_id": voiceActing.translatorId, "action": "get_episodes", "favs": favs])
        case let .getComments(movieId, page, type, commentId, skin):
            return try request.query([
                "news_id": movieId,
                "cstart": page ?? 1,
                "t": Int.timestamp,
                "type": type ?? 0,
                "comment_id": commentId ?? 0,
                "skin": skin ?? "hdrezka",
            ])
        case let .toggleCommentLike(id):
            return try request.body(["id": id])
        case let .reportComment(id, issue, text):
            return try request.body(["id": id, "issue_id": issue, "text": text, "action": "comments"])
        case let .deleteComment(id, hash):
            return try request.query(["id": id, "dle_allow_hash": hash, "type": 0, "area": "ajax"])
        case let .sendComment(id, postId, name, text, adb, type):
            var params: Parameters = ["parent": id ?? 0, "post_id": postId, "comments": text, "has_adb": adb ?? 1, "g_recaptcha_response": ""]
            params["replyto_id"] = id
            params["name"] = name
            params["type"] = type

            return try request.body(params)
        case let .getlikes(id):
            return try request.body(["comment_id": id])
        case let .rate(id, rating):
            return try request.body(["news_id": id, "go_rate": rating, "skin": "hdrezka"])
        case .getMovieDetails:
            return request
        }
    }
}

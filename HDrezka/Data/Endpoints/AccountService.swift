import Alamofire
import Defaults
import Foundation

enum AccountService {
    case signIn(login: String, password: String)
    case signUp(email: String, login: String, password: String, verifyCode: String, step: Int)
    case restore(login: String)
    case logout
    case getWatchingLaterMovies
    case sendWatching(postId: String, translatorId: String, season: String?, episode: String?, currentTime: Int?, duration: Int?)
    case switchWatchedItem(id: String)
    case removeWatchingItem(id: String)
    case getSeriesUpdates
    case getBookmarks
    case getBookmarksByCategory(id: Int, filter: String, genre: Int, page: Int)
    case createBookmarkCategory(name: String)
    case changeBookmarkCategoryName(newName: String, catId: Int)
    case deleteBookmarkCategory(catId: Int)
    case addToBookmarks(movieId: String, catId: Int)
    case removeFromBookmarks(movies: [String], catId: Int)
    case moveBetweenBookmarks(movies: [String], fromCatId: Int, toCatId: Int)
    case reorderBookmarksCategories(newOrder: [Bookmark])
    case getVersion
}

extension AccountService: Endpoint {
    var baseURL: URL {
        switch self {
        case .getVersion:
            Const.fakeUpdate
        default:
            Defaults[.mirror]
        }
    }

    var path: String {
        switch self {
        case .signIn:
            "ajax/login/"
        case .signUp:
            "ajax/registration/"
        case .restore:
            "index.php"
        case .logout:
            "logout/"
        case .getWatchingLaterMovies:
            "continue/"
        case .sendWatching:
            "ajax/send_save/"
        case .switchWatchedItem:
            "engine/ajax/cdn_saves_view.php"
        case .removeWatchingItem:
            "engine/ajax/cdn_saves_remove.php"
        case .getSeriesUpdates:
            ""
        case .getBookmarks:
            "favorites/"
        case let .getBookmarksByCategory(id, _, _, page):
            "favorites/\(id)/".page(page)
        case .createBookmarkCategory, .changeBookmarkCategoryName, .deleteBookmarkCategory, .addToBookmarks, .reorderBookmarksCategories, .removeFromBookmarks, .moveBetweenBookmarks:
            "ajax/favorites/"
        case .getVersion:
            "get.hdrezka_android_app_updates"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .signIn, .signUp, .restore, .sendWatching, .switchWatchedItem, .removeWatchingItem, .createBookmarkCategory, .changeBookmarkCategoryName, .deleteBookmarkCategory, .addToBookmarks, .reorderBookmarksCategories, .removeFromBookmarks, .moveBetweenBookmarks:
            .post
        default:
            .get
        }
    }

    func encode(_ request: URLRequest) throws -> URLRequest {
        switch self {
        case let .signIn(login, password):
            return try request.body(["login_name": login, "login_password": password, "login_not_save": 0])
        case let .signUp(email, login, password, verifyCode, step):
            return try request.body(["email": email, "login": login, "password": password, "rules": 1, "verify_code": verifyCode, "step": step])
        case let .restore(login):
            return try request.query(["do": "lostpassword"]).body(["lostname": login, "sumbit": 1, "submit_lost": "submit_lost"])
        case let .sendWatching(postId, translatorId, season, episode, currentTime, duration):
            var params: Parameters = ["post_id": postId, "translator_id": translatorId, "season": season ?? "0", "episode": episode ?? "0"]
            params["current_time"] = currentTime
            params["duration"] = duration

            return try request.timestamped().body(params)
        case let .switchWatchedItem(id), let .removeWatchingItem(id):
            return try request.body(["id": id])
        case let .getBookmarksByCategory(_, filter, genre, _):
            var params: Parameters = ["filter": filter]
            if genre != 0 {
                params["genre"] = genre
            }

            return try request.query(params)
        case let .createBookmarkCategory(name):
            return try request.body(["name": name, "action": "add_cat"])
        case let .changeBookmarkCategoryName(newName, catId):
            return try request.body(["name": newName, "cat_id": catId, "action": "change_cat_name"])
        case let .deleteBookmarkCategory(catId):
            return try request.body(["cat_id": catId, "action": "remove_cat"])
        case let .addToBookmarks(movieId, catId):
            return try request.body(["post_id": movieId, "cat_id": catId, "action": "add_post"])
        case let .removeFromBookmarks(movies, catId):
            return try request.body(["items": movies, "cat_id": catId, "action": "remove_items"])
        case let .moveBetweenBookmarks(movies, fromCatId, toCatId):
            return try request.body(["from_cat_id": fromCatId, "to_cat_id": toCatId, "items": movies, "action": "change_items_cat"])
        case let .reorderBookmarksCategories(newOrder):
            return try request.body(["cats": newOrder.map(\.bookmarkId), "action": "sort_cats"])
        case .logout, .getWatchingLaterMovies, .getSeriesUpdates, .getBookmarks, .getVersion:
            return request
        }
    }
}

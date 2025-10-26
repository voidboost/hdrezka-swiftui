import Alamofire
import Defaults
import Foundation

enum AccountService {
    case signIn(login: String, password: String)
    case signUp(email: String, login: String, password: String)
    case restore(login: String)
    case checkEmail(email: String)
    case checkUsername(username: String)
    case getWatchingLaterMovies
    case sendWatching(postId: String, translatorId: String, season: String?, episode: String?, currentTime: Int, duration: Int? = nil)
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

extension AccountService: URLRequestConvertible {
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
            "engine/ajax/quick_register.php"
        case .restore:
            "index.php"
        case .checkEmail, .checkUsername:
            "engine/ajax/registration.php"
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
        case .signIn, .signUp, .restore, .checkEmail, .checkUsername, .sendWatching, .switchWatchedItem, .removeWatchingItem, .createBookmarkCategory, .changeBookmarkCategoryName, .deleteBookmarkCategory, .addToBookmarks, .reorderBookmarksCategories, .removeFromBookmarks, .moveBetweenBookmarks:
            .post
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
        case let .signIn(login, password):
            return try URLEncoding.httpBody.encode(request, with: ["login_name": login, "login_password": password, "login_not_save": "0"])
        case let .signUp(email, login, password):
            return try URLEncoding.httpBody.encode(request, with: ["data": ["email": email, "prevent_autofill_name": "", "name": login, "prevent_autofill_password1": "", "password1": password, "rules": "1", "submit_reg": "submit_reg", "do": "register"].map { "\($0)=\($1)" }.joined(separator: "&")])
        case let .restore(login):
            return try URLEncoding.httpBody.encode(URLEncoding.queryString.encode(request, with: ["do": "lostpassword"]), with: ["lostname": login, "sumbit": "1", "submit_lost": "submit_lost"])
        case let .checkEmail(email):
            return try URLEncoding.httpBody.encode(request, with: ["email": email])
        case let .checkUsername(username):
            return try URLEncoding.httpBody.encode(request, with: ["name": username])
        case let .sendWatching(postId, translatorId, season, episode, currentTime, duration):
            var params: [String: Any] = [:]
            params["post_id"] = postId
            params["translator_id"] = translatorId
            params["season"] = season ?? "0"
            params["episode"] = episode ?? "0"
            params["current_time"] = currentTime
            params["duration"] = duration

            return try URLEncoding.httpBody.encode(URLEncoding.queryString.encode(request, with: ["t": Int(Date().timeIntervalSince1970 * 1000)]), with: params)
        case let .switchWatchedItem(id):
            return try URLEncoding.httpBody.encode(request, with: ["id": id])
        case let .removeWatchingItem(id):
            return try URLEncoding.httpBody.encode(request, with: ["id": id])
        case let .getBookmarksByCategory(_, filter, genre, _):
            var params: [String: Any] = [:]
            params["filter"] = filter
            if genre != 0 {
                params["genre"] = genre
            }

            return try URLEncoding.queryString.encode(request, with: params)
        case let .createBookmarkCategory(name):
            return try URLEncoding.httpBody.encode(request, with: ["name": name, "action": "add_cat"])
        case let .changeBookmarkCategoryName(newName, catId):
            return try URLEncoding.httpBody.encode(request, with: ["name": newName, "cat_id": catId, "action": "change_cat_name"])
        case let .deleteBookmarkCategory(catId):
            return try URLEncoding.httpBody.encode(request, with: ["cat_id": catId, "action": "remove_cat"])
        case let .addToBookmarks(movieId, catId):
            return try URLEncoding.httpBody.encode(request, with: ["post_id": movieId, "cat_id": catId, "action": "add_post"])
        case let .removeFromBookmarks(movies, catId):
            return try URLEncoding.httpBody.encode(request, with: ["items": movies, "cat_id": catId, "action": "remove_items"])
        case let .moveBetweenBookmarks(movies, fromCatId, toCatId):
            return try URLEncoding.httpBody.encode(request, with: ["from_cat_id": fromCatId, "to_cat_id": toCatId, "items": movies, "action": "change_items_cat"])
        case let .reorderBookmarksCategories(newOrder):
            return try URLEncoding.httpBody.encode(request, with: ["cats": newOrder.map(\.bookmarkId), "action": "sort_cats"])
        default:
            return request
        }
    }
}

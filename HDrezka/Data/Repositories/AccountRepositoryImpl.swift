import Alamofire
import Combine
import Defaults
import FactoryKit
import Foundation

struct AccountRepositoryImpl: AccountRepository {
    @Injected(\.session) private var session

    func signIn(login: String, password: String) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.signIn(login: login, password: password))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool
                else {
                    throw HDrezkaError.parseJson("success", "signIn")
                }

                return success
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func signUp(email: String, login: String, password: String) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.signUp(email: email, login: login, password: password))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(AccountParser.checkRegistration)
            .handleError()
            .eraseToAnyPublisher()
    }

    func restore(login: String) -> AnyPublisher<String?, Error> {
        session.request(AccountService.restore(login: login))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(AccountParser.checkRestore)
            .handleError()
            .eraseToAnyPublisher()
    }

    func logout() {
        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)

        Defaults[.isLoggedIn] = false
        Defaults[.isUserPremium] = nil
    }

    func checkEmail(email: String) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.checkEmail(email: email))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(AccountParser.checkRegistrationData)
            .handleError()
            .eraseToAnyPublisher()
    }

    func checkUsername(username: String) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.checkUsername(username: username))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(AccountParser.checkRegistrationData)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getWatchingLaterMovies() -> AnyPublisher<[MovieWatchLater], Error> {
        session.request(AccountService.getWatchingLaterMovies)
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(AccountParser.parseWatchingLaterMovies)
            .handleError()
            .eraseToAnyPublisher()
    }

    func saveWatchingState(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, position: Int, total: Int) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.sendWatching(postId: voiceActing.voiceId, translatorId: voiceActing.translatorId, season: season?.seasonId, episode: episode?.episodeId, currentTime: position, duration: total != 1 ? total : nil))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool
                else {
                    throw HDrezkaError.parseJson("success", "saveWatchingState")
                }

                return success
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func switchWatchedItem(item: MovieWatchLater) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.switchWatchedItem(id: item.dataId))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool
                else {
                    throw HDrezkaError.parseJson("success", "switchWatchedItem")
                }

                return success
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func removeWatchingItem(item: MovieWatchLater) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.removeWatchingItem(id: item.dataId))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool
                else {
                    throw HDrezkaError.parseJson("success", "removeWatchingItem")
                }

                return success
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func getSeriesUpdates() -> AnyPublisher<[SeriesUpdateGroup], Error> {
        session.request(AccountService.getSeriesUpdates)
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(AccountParser.parseSeriesUpdates)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getBookmarks() -> AnyPublisher<[Bookmark], Error> {
        session.request(AccountService.getBookmarks)
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(AccountParser.parseBookmarks)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getBookmarksByCategoryAdded(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(AccountService.getBookmarksByCategory(id: id, filter: "added", genre: genre, page: page))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getBookmarksByCategoryYear(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(AccountService.getBookmarksByCategory(id: id, filter: "year", genre: genre, page: page))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func getBookmarksByCategoryPopular(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.request(AccountService.getBookmarksByCategory(id: id, filter: "popular", genre: genre, page: page))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(MovieListsParser.parse)
            .map(\.1)
            .handleError()
            .eraseToAnyPublisher()
    }

    func createBookmarksCategory(name: String) -> AnyPublisher<Bookmark, Error> {
        session.request(AccountService.createBookmarkCategory(name: name))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let id = json["id"] as? Int
                else {
                    throw HDrezkaError.parseJson("id", "createBookmarksCategory")
                }

                return Bookmark(bookmarkId: id, name: name, count: 0)
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func changeBookmarksCategoryName(id: Int, newName: String) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.changeBookmarkCategoryName(newName: newName, catId: id))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool
                else {
                    throw HDrezkaError.parseJson("success", "changeBookmarksCategoryName")
                }

                return success
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func deleteBookmarksCategory(id: Int) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.deleteBookmarkCategory(catId: id))
            .validate(statusCode: 200 ..< 400)
            .publishUnserialized()
            .value()
            .tryMap { _ in true }
            .handleError()
            .eraseToAnyPublisher()
    }

    func addToBookmarks(movieId: String, bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.addToBookmarks(movieId: movieId, catId: bookmarkUserCategory))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool
                else {
                    throw HDrezkaError.parseJson("success", "addToBookmarks")
                }

                return success
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func removeFromBookmarks(movies: [String], bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.removeFromBookmarks(movies: movies, catId: bookmarkUserCategory))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool
                else {
                    throw HDrezkaError.parseJson("success", "removeFromBookmarks")
                }

                return success
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func moveBetweenBookmarks(movies: [String], fromBookmarkUserCategory: Int, toBookmarkUserCategory: Int) -> AnyPublisher<Int, Error> {
        session.request(AccountService.moveBetweenBookmarks(movies: movies, fromCatId: fromBookmarkUserCategory, toCatId: toBookmarkUserCategory))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let moved = json["moved"] as? Int
                else {
                    throw HDrezkaError.parseJson("moved", "moveBetweenBookmarks")
                }

                return moved
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func reorderBookmarksCategories(newOrder: [Bookmark]) -> AnyPublisher<Bool, Error> {
        session.request(AccountService.reorderBookmarksCategories(newOrder: newOrder))
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let success = json["success"] as? Bool
                else {
                    throw HDrezkaError.parseJson("success", "reorderBookmarksCategories")
                }

                return success
            }
            .handleError()
            .eraseToAnyPublisher()
    }

    func getVersion() -> AnyPublisher<String, Error> {
        session.request(AccountService.getVersion)
            .validate(statusCode: 200 ..< 400)
            .publishData()
            .value()
            .tryMap { res in
                guard let json = try? JSONSerialization.jsonObject(with: res, options: .fragmentsAllowed) as? [String: Any],
                      let version = json["version"] as? String
                else {
                    throw HDrezkaError.parseJson("version", "getVersion")
                }

                return version
            }
            .handleError()
            .eraseToAnyPublisher()
    }
}

import Alamofire
import Combine
import Defaults
import Dependencies
import Foundation
import SwiftSoup

struct AccountRepositoryImpl: AccountRepository {
    @Dependency(\.session) private var session

    private func authorize(_ convertible: AccountService, function: String, fallback: @escaping (String, SwiftSoup.Document) throws -> [String]) -> AnyPublisher<Void, Error> {
        session.json(convertible, function: function) { json in
            let success: Bool = try json.require("success")

            guard success else {
                let message: String = try json.require("message")

                let document = try SwiftSoup.parseHTML(
                    message,
                    Defaults[.mirror].absoluteString,
                )

                let messages = try document.select("ul").first()?.select("li").map { li in try li.text() } ?? fallback(message, document)

                throw HDrezkaError.site(messages)
            }
        }
    }

    private func bookmarksByCategory(id: Int, filter: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        session.string(AccountService.getBookmarksByCategory(id: id, filter: filter, genre: genre, page: page)) { try MovieListsParser.parse(from: $0).1 }
    }

    func signIn(login: String, password: String) -> AnyPublisher<Void, Error> {
        authorize(.signIn(login: login, password: password), function: "signIn") { message, _ in
            message.split(whereSeparator: \.isNewline).map(String.init)
        }
    }

    func signUp(email: String, login: String, password: String, verifyCode: String, step: Int) -> AnyPublisher<Void, Error> {
        authorize(.signUp(email: email, login: login, password: password, verifyCode: verifyCode, step: step), function: "signUp") { _, document in
            try document.text().split(whereSeparator: \.isNewline).map(String.init)
        }
    }

    func restore(login: String) -> AnyPublisher<String?, Error> {
        session.string(AccountService.restore(login: login.trim()), parse: AccountParser.checkRestore)
    }

    func logout() -> AnyPublisher<Bool, Error> {
        session.perform(AccountService.logout)
    }

    func getWatchingLaterMovies() -> AnyPublisher<[MovieWatchLater], Error> {
        session.string(AccountService.getWatchingLaterMovies, parse: AccountParser.parseWatchingLaterMovies)
    }

    func saveWatchingState(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, position: Int?, total: Int?) -> AnyPublisher<Bool, Error> {
        session.success(AccountService.sendWatching(postId: voiceActing.voiceId, translatorId: voiceActing.translatorId, season: season?.seasonId, episode: episode?.episodeId, currentTime: position, duration: total != 1 ? total : nil), function: "saveWatchingState")
    }

    func switchWatchedItem(item: MovieWatchLater) -> AnyPublisher<Bool, Error> {
        session.success(AccountService.switchWatchedItem(id: item.dataId), function: "switchWatchedItem")
    }

    func removeWatchingItem(item: MovieWatchLater) -> AnyPublisher<Bool, Error> {
        session.success(AccountService.removeWatchingItem(id: item.dataId), function: "removeWatchingItem")
    }

    func getSeriesUpdates() -> AnyPublisher<[SeriesUpdateGroup], Error> {
        session.string(AccountService.getSeriesUpdates, parse: AccountParser.parseSeriesUpdates)
    }

    func getBookmarks() -> AnyPublisher<[Bookmark], Error> {
        session.string(AccountService.getBookmarks, parse: AccountParser.parseBookmarks)
    }

    func getBookmarksByCategoryAdded(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        bookmarksByCategory(id: id, filter: "added", genre: genre, page: page)
    }

    func getBookmarksByCategoryYear(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        bookmarksByCategory(id: id, filter: "year", genre: genre, page: page)
    }

    func getBookmarksByCategoryPopular(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        bookmarksByCategory(id: id, filter: "popular", genre: genre, page: page)
    }

    func createBookmarksCategory(name: String) -> AnyPublisher<Bookmark, Error> {
        session.json(AccountService.createBookmarkCategory(name: name), function: "createBookmarksCategory") { json in
            try Bookmark(bookmarkId: json.require("id"), name: name, count: 0)
        }
    }

    func changeBookmarksCategoryName(id: Int, newName: String) -> AnyPublisher<Bool, Error> {
        session.success(AccountService.changeBookmarkCategoryName(newName: newName, catId: id), function: "changeBookmarksCategoryName")
    }

    func deleteBookmarksCategory(id: Int) -> AnyPublisher<Bool, Error> {
        session.perform(AccountService.deleteBookmarkCategory(catId: id))
    }

    func addToBookmarks(movieId: String, bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error> {
        session.success(AccountService.addToBookmarks(movieId: movieId, catId: bookmarkUserCategory), function: "addToBookmarks")
    }

    func removeFromBookmarks(movies: [String], bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error> {
        session.success(AccountService.removeFromBookmarks(movies: movies, catId: bookmarkUserCategory), function: "removeFromBookmarks")
    }

    func moveBetweenBookmarks(movies: [String], fromBookmarkUserCategory: Int, toBookmarkUserCategory: Int) -> AnyPublisher<Int, Error> {
        session.json(AccountService.moveBetweenBookmarks(movies: movies, fromCatId: fromBookmarkUserCategory, toCatId: toBookmarkUserCategory), function: "moveBetweenBookmarks") { json in
            try json.require("moved")
        }
    }

    func reorderBookmarksCategories(newOrder: [Bookmark]) -> AnyPublisher<Bool, Error> {
        session.success(AccountService.reorderBookmarksCategories(newOrder: newOrder), function: "reorderBookmarksCategories")
    }

    func getVersion() -> AnyPublisher<String, Error> {
        session.json(AccountService.getVersion, function: "getVersion") { json in
            try json.require("version")
        }
    }
}

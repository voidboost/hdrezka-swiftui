import Alamofire
import Dependencies
import Foundation
import SwiftSoup

struct AccountRepositoryImpl: AccountRepository {
    @Dependency(\.session) private var session

    private func authorize(_ convertible: AccountService, function: String) async throws {
        try await session.json(convertible, function: function) { json in
            let success: Bool = try json.require("success")

            guard success else {
                if let message: String = json["message"], !message.isEmpty {
                    if let document = try? message.parseHTML() {
                        if let messages = try? document.select("ul").first()?.select("li").map({ li in try li.text() }), !messages.isEmpty {
                            throw HDrezkaError.site(messages)
                        } else if let messages = try? document.text().split(whereSeparator: \.isNewline).map(String.init), !messages.isEmpty {
                            throw HDrezkaError.site(messages)
                        }
                    }

                    throw HDrezkaError.site(message.split(whereSeparator: \.isNewline).map(String.init))
                } else if let messages: [String: String] = json["message"], !messages.isEmpty {
                    throw HDrezkaError.site(Array(messages.values))
                } else {
                    throw HDrezkaError.unknown
                }
            }
        }
    }

    func signIn(login: String, password: String) async throws {
        try await authorize(.signIn(login: login, password: password), function: "signIn")
    }

    func signUp(email: String, login: String, password: String, verifyCode: String, step: Int) async throws {
        try await authorize(.signUp(email: email, login: login, password: password, verifyCode: verifyCode, step: step), function: "signUp")
    }

    func restore(login: String) async throws -> String? {
        try await session.string(AccountService.restore(login: login.trim()), parse: AccountParser.checkRestore)
    }

    func logout() async throws {
        try await session.perform(AccountService.logout)
    }

    func getWatchingLaterMovies() async throws -> [MovieWatchLater] {
        try await session.page(AccountService.getWatchingLaterMovies, parse: AccountParser.parseWatchingLaterMovies)
    }

    func saveWatchingState(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, position: Int?, total: Int?) async throws {
        try await session.success(AccountService.sendWatching(postId: voiceActing.voiceId, translatorId: voiceActing.translatorId, season: season?.seasonId, episode: episode?.episodeId, currentTime: position, duration: total != 1 ? total : nil), function: "saveWatchingState")
    }

    func switchWatchedItem(item: MovieWatchLater) async throws {
        try await session.success(AccountService.switchWatchedItem(id: item.dataId), function: "switchWatchedItem")
    }

    func removeWatchingItem(item: MovieWatchLater) async throws {
        try await session.success(AccountService.removeWatchingItem(id: item.dataId), function: "removeWatchingItem")
    }

    func getSeriesUpdates() async throws -> [SeriesUpdateGroup] {
        try await session.page(AccountService.getSeriesUpdates, parse: AccountParser.parseSeriesUpdates)
    }

    func getBookmarks() async throws -> [Bookmark] {
        try await session.page(AccountService.getBookmarks, parse: AccountParser.parseBookmarks)
    }

    func getBookmarksByCategory(id: Int, filter: BookmarkFilters, genre: Int, page: Int) async throws -> [MovieSimple] {
        try await session.page(AccountService.getBookmarksByCategory(id: id, filter: filter.query, genre: genre, page: page), parse: MovieListsParser.parseMovies)
    }

    func createBookmarksCategory(name: String) async throws -> Bookmark {
        try await session.json(AccountService.createBookmarkCategory(name: name), function: "createBookmarksCategory") { json in
            try Bookmark(bookmarkId: json.require("id"), name: name, count: 0)
        }
    }

    func changeBookmarksCategoryName(id: Int, newName: String) async throws {
        try await session.success(AccountService.changeBookmarkCategoryName(newName: newName, catId: id), function: "changeBookmarksCategoryName")
    }

    func deleteBookmarksCategory(id: Int) async throws {
        try await session.perform(AccountService.deleteBookmarkCategory(catId: id))
    }

    func addToBookmarks(movieId: String, bookmarkUserCategory: Int) async throws {
        try await session.success(AccountService.addToBookmarks(movieId: movieId, catId: bookmarkUserCategory), function: "addToBookmarks")
    }

    func removeFromBookmarks(movies: [String], bookmarkUserCategory: Int) async throws {
        try await session.success(AccountService.removeFromBookmarks(movies: movies, catId: bookmarkUserCategory), function: "removeFromBookmarks")
    }

    func moveBetweenBookmarks(movies: [String], fromBookmarkUserCategory: Int, toBookmarkUserCategory: Int) async throws -> Int {
        try await session.json(AccountService.moveBetweenBookmarks(movies: movies, fromCatId: fromBookmarkUserCategory, toCatId: toBookmarkUserCategory), function: "moveBetweenBookmarks") { json in
            try json.require("moved")
        }
    }

    func reorderBookmarksCategories(newOrder: [Bookmark]) async throws {
        try await session.success(AccountService.reorderBookmarksCategories(newOrder: newOrder), function: "reorderBookmarksCategories")
    }

    func getVersion() async throws -> String {
        try await session.json(AccountService.getVersion, function: "getVersion") { json in
            try json.require("version")
        }
    }
}

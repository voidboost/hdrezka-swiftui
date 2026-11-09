import Alamofire
import Dependencies
import DependenciesMacros
import Foundation
import SwiftSoup

@DependencyClient
struct AccountClient {
    var signIn: @Sendable (_ login: String, _ password: String) async throws -> Void
    var signUp: @Sendable (_ email: String, _ login: String, _ password: String, _ verifyCode: String, _ step: Int) async throws -> Void
    var restore: @Sendable (_ login: String) async throws -> String?
    var logout: @Sendable () async throws -> Void
    var getWatchingLaterMovies: @Sendable () async throws -> [MovieWatchLater]
    var saveWatchingState: @Sendable (_ voiceActing: MovieVoiceActing, _ season: MovieSeason?, _ episode: MovieEpisode?, _ position: Int?, _ total: Int?) async throws -> Void
    var switchWatchedItem: @Sendable (_ item: MovieWatchLater) async throws -> Void
    var removeWatchingItem: @Sendable (_ item: MovieWatchLater) async throws -> Void
    var getSeriesUpdates: @Sendable () async throws -> [SeriesUpdateGroup]
    var getBookmarks: @Sendable () async throws -> [Bookmark]
    var getBookmarksByCategory: @Sendable (_ id: Int, _ filter: BookmarkFilters, _ genre: Int, _ page: Int) async throws -> [MovieSimple]
    var createBookmarksCategory: @Sendable (_ name: String) async throws -> Bookmark
    var changeBookmarksCategoryName: @Sendable (_ id: Int, _ newName: String) async throws -> Void
    var deleteBookmarksCategory: @Sendable (_ id: Int) async throws -> Void
    var addToBookmarks: @Sendable (_ movieId: String, _ bookmarkUserCategory: Int) async throws -> Void
    var removeFromBookmarks: @Sendable (_ movies: [String], _ bookmarkUserCategory: Int) async throws -> Void
    var moveBetweenBookmarks: @Sendable (_ movies: [String], _ fromBookmarkUserCategory: Int, _ toBookmarkUserCategory: Int) async throws -> Int
    var reorderBookmarksCategories: @Sendable (_ newOrder: [Bookmark]) async throws -> Void
    var getVersion: @Sendable () async throws -> String
}

extension AccountClient {
    func saveWatchingState(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?) async throws {
        try await saveWatchingState(voiceActing: voiceActing, season: season, episode: episode, position: nil, total: nil)
    }
}

extension AccountClient: DependencyKey {
    static let liveValue: Self = {
        @Dependency(\.session) var session

        return Self(
            signIn: { login, password in
                try await session.authorize(.signIn(login: login, password: password), function: "signIn")
            },
            signUp: { email, login, password, verifyCode, step in
                try await session.authorize(.signUp(email: email, login: login, password: password, verifyCode: verifyCode, step: step), function: "signUp")
            },
            restore: { login in
                try await session.string(AccountService.restore(login: login.trim()), parse: AccountParser.checkRestore)
            },
            logout: {
                try await session.perform(AccountService.logout)
            },
            getWatchingLaterMovies: {
                try await session.page(AccountService.getWatchingLaterMovies, parse: AccountParser.parseWatchingLaterMovies)
            },
            saveWatchingState: { voiceActing, season, episode, position, total in
                try await session.success(AccountService.sendWatching(postId: voiceActing.voiceId, translatorId: voiceActing.translatorId, season: season?.seasonId, episode: episode?.episodeId, currentTime: position, duration: total != 1 ? total : nil), function: "saveWatchingState")
            },
            switchWatchedItem: { item in
                try await session.success(AccountService.switchWatchedItem(id: item.dataId), function: "switchWatchedItem")
            },
            removeWatchingItem: { item in
                try await session.success(AccountService.removeWatchingItem(id: item.dataId), function: "removeWatchingItem")
            },
            getSeriesUpdates: {
                try await session.page(AccountService.getSeriesUpdates, parse: AccountParser.parseSeriesUpdates)
            },
            getBookmarks: {
                try await session.page(AccountService.getBookmarks, parse: AccountParser.parseBookmarks)
            },
            getBookmarksByCategory: { id, filter, genre, page in
                try await session.page(AccountService.getBookmarksByCategory(id: id, filter: filter.query, genre: genre, page: page), parse: MovieListsParser.parseMovies)
            },
            createBookmarksCategory: { name in
                try await session.json(AccountService.createBookmarkCategory(name: name), function: "createBookmarksCategory") { json in
                    try Bookmark(bookmarkId: json.require("id"), name: name, count: 0)
                }
            },
            changeBookmarksCategoryName: { id, newName in
                try await session.success(AccountService.changeBookmarkCategoryName(newName: newName, catId: id), function: "changeBookmarksCategoryName")
            },
            deleteBookmarksCategory: { id in
                try await session.perform(AccountService.deleteBookmarkCategory(catId: id))
            },
            addToBookmarks: { movieId, bookmarkUserCategory in
                try await session.success(AccountService.addToBookmarks(movieId: movieId, catId: bookmarkUserCategory), function: "addToBookmarks")
            },
            removeFromBookmarks: { movies, bookmarkUserCategory in
                try await session.success(AccountService.removeFromBookmarks(movies: movies, catId: bookmarkUserCategory), function: "removeFromBookmarks")
            },
            moveBetweenBookmarks: { movies, fromBookmarkUserCategory, toBookmarkUserCategory in
                try await session.json(AccountService.moveBetweenBookmarks(movies: movies, fromCatId: fromBookmarkUserCategory, toCatId: toBookmarkUserCategory), function: "moveBetweenBookmarks") { json in
                    try json.require("moved")
                }
            },
            reorderBookmarksCategories: { newOrder in
                try await session.success(AccountService.reorderBookmarksCategories(newOrder: newOrder), function: "reorderBookmarksCategories")
            },
            getVersion: {
                try await session.json(AccountService.getVersion, function: "getVersion") { json in
                    try json.require("version")
                }
            },
        )
    }()
}

extension DependencyValues {
    var accountClient: AccountClient {
        get { self[AccountClient.self] }
        set { self[AccountClient.self] = newValue }
    }
}

private extension Session {
    func authorize(_ convertible: AccountService, function: String) async throws {
        try await json(convertible, function: function) { json in
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
}

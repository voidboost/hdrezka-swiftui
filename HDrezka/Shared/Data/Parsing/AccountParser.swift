import Foundation
import SwiftSoup

class AccountParser {
    static func parseWatchingLaterMovies(from: String) throws -> [MovieWatchLater] {
        try SwiftSoup.parse(from)
            .checker()
            .getWatchingLaterMovies()
            .map { movie in
                try MovieWatchLater(
                    watchLaterId: movie.getWatchingLaterId(),
                    name: movie.getWatchingLaterName(),
                    cover: movie.getWatchingLaterCover(),
                    details: movie.getWatchingLaterDetails(),
                    watchingInfo: movie.getWatchingLaterInfo(),
                    date: movie.getWatchingLaterDate(),
                    buttonText: movie.getWatchingLaterButtonText(),
                    dataId: movie.getWatchingLaterDataId(),
                    watched: movie.getWatchingLaterWatched(),
                )
            }
    }

    static func parseSeriesUpdates(from: String) throws -> [SeriesUpdateGroup] {
        try SwiftSoup.parse(from)
            .checker()
            .getSeriesUpdateGroups()
            .compactMap { group in
                let date = try group.getSeriesUpdateGroupDate()

                let items = try group
                    .getSeriesUpdateItems()
                    .map { item in
                        try SeriesUpdateItem(
                            seriesId: item.getSeriesUpdateId(),
                            seriesName: item.getSeriesUpdateName(),
                            season: item.getSeriesUpdateSeason(),
                            releasedEpisode: item.getSeriesUpdateReleasedEpisode(),
                            chosenVoiceActing: item.getSeriesUpdateVoiceActing(),
                            isChosenVoiceActingPremium: item.isSeriesUpdateVoiceActingPremium(),
                            tracked: item.hasClass("tracked"),
                        )
                    }

                if !items.isEmpty {
                    return SeriesUpdateGroup(date: date, releasedEpisodes: items)
                } else {
                    return nil
                }
            }
    }

    static func checkRegistration(from: String) throws -> Bool {
        guard let scriptValue = try SwiftSoup.parse(from).select("script").first()?.html() else { return false }

        return scriptValue.contains("location") || scriptValue.isEmpty
    }

    static func checkRegistrationData(from: String) throws -> Bool {
        try !SwiftSoup.parse(from).select(".string-ok").isEmpty()
    }

    static func checkRestore(from: String) throws -> String? {
        guard try SwiftSoup.parse(from).select(".b-info__title").text().contains("Запрос успешно принят") else { return nil }

        return try SwiftSoup.parse(from).select(".b-info__message b").first()?.text()
    }

    static func parseBookmarks(from: String) throws -> [Bookmark] {
        try SwiftSoup.parse(from)
            .checker()
            .getBookmarksCategories()
            .map { category in
                try Bookmark(
                    bookmarkId: category.getBookmarksCategoryId(),
                    name: category.getBookmarksCategoryName(),
                    count: category.getBookmarksCategoryCount(),
                )
            }
    }
}

private extension Document {
    func getWatchingLaterMovies() throws -> Elements {
        try select(".b-videosaves__list_item[id^=videosave]")
    }

    func getSeriesUpdateGroups() throws -> Elements {
        try select(".b-seriesupdate__block")
    }

    func getBookmarksCategories() throws -> Elements {
        try select(".b-favorites_content__cats_list_item")
    }
}

private extension Element {
    func getWatchingLaterId() throws -> String {
        try select(".td.title a").first().orThrow().attr("href").cleanPath.orThrow()
    }

    func getWatchingLaterCover() throws -> String {
        try select(".td.title a").first().orThrow().attr("data-cover_url")
    }

    func getWatchingLaterName() throws -> String {
        try select(".td.title").first().orThrow().select("a").text()
    }

    func getWatchingLaterDetails() throws -> String {
        try select(".td.title").first().orThrow().select("small").text()
    }

    func getWatchingLaterInfo() throws -> String {
        let tdInfo = try select(".td.info").first().orThrow()

        if let temp = try tdInfo.select("span").first()?.text() {
            return try tdInfo.text().replacingOccurrences(of: temp, with: "")
        } else {
            return try tdInfo.text()
        }
    }

    func getWatchingLaterDataId() throws -> String {
        try select(".i-sprt.delete").first().orThrow().attr("data-id")
    }

    func getWatchingLaterWatched() throws -> Bool {
        try select(".i-sprt.view").first().orThrow().hasClass("watched")
    }

    func getWatchingLaterDate() throws -> String {
        try select(".td.date").text()
    }

    func getWatchingLaterButtonText() throws -> String? {
        try select(".td.info span").first()?.text()
    }

    func getSeriesUpdateItems() throws -> Elements {
        try select(".b-seriesupdate__block_list_item")
    }

    func getSeriesUpdateId() throws -> String {
        try select(".b-seriesupdate__block_list_link").attr("href").cleanPath.orThrow()
    }

    func getSeriesUpdateName() throws -> String {
        try select(".b-seriesupdate__block_list_link").text()
    }

    func getSeriesUpdateSeason() throws -> String {
        try select(".season").text()
    }

    func getSeriesUpdateReleasedEpisode() throws -> String {
        let span = try select(".cell.cell-2")

        return try span.text().replacingOccurrences(of: span.select("i").text(), with: "")
    }

    func getSeriesUpdateVoiceActing() throws -> String {
        try select(".cell.cell-2 i").text()
    }

    func isSeriesUpdateVoiceActingPremium() throws -> Bool {
        try !select(".cell.cell-2 i").select(".b-content__inline_item-prem-label").isEmpty()
    }

    func getSeriesUpdateGroupDate() throws -> String {
        let blockDate = try select(".b-seriesupdate__block_date").first().orThrow()

        try blockDate.select(".act").first()?.remove()

        return try blockDate.text()
    }

    func getBookmarksCategoryId() throws -> Int {
        try Int(attr("data-cat_id")).orThrow()
    }

    func getBookmarksCategoryName() throws -> String {
        try select(".name").text()
    }

    func getBookmarksCategoryCount() throws -> Int {
        try Int(select(".num-holder .fb-1").text()).orThrow()
    }
}

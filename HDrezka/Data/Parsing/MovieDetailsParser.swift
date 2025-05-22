import Algorithms
import Defaults
import Foundation
import OrderedCollections
import SwiftSoup
import SwiftUI

class MovieDetailsParser {
    static func parseMovieDetails(from: String, movieId: String) throws -> MovieDetailed {
        let site = try SwiftSoup.parse(from).checker()
        let content = try site.getDetailsContent()

        let nameRussian = try content.getDetailsRussianName()
        let nameOriginal = try content.getDetailsOriginalName()
        let hposter = try content.getDetailsHPoster()
        let poster = try content.getDetailsPoster()
        let description = try content.getDetailsDescription()
        let isAvailable = try site.isAvailable()
        let isComingSoon = try site.isComingSoon()
        let voiceActing: [MovieVoiceActing]? = if isAvailable, !isComingSoon, let movieId = movieId.id {
            try site.getDetailsVoiceActing(movieId: movieId)
        } else {
            nil
        }
        let series: Series? = if isAvailable, !isComingSoon, let acting = voiceActing?.first(where: { $0.isSelected }), let seasons = try site.getSeasons(), let season = seasons.first(where: { $0.isSelected }), let episode = season.episodes.first(where: { $0.isSelected }) {
            Series(acting: acting.translatorId, season: season.seasonId, episode: episode.episodeId)
        } else {
            nil
        }
        let rated = try content.isRatedDetails()
        let rating = try content.getDetailsRating()
        let votes = try content.getDetailsVotes()

        let schedule = try site.getDetailsSchedule()
        let franchise = try site.getDetailsFranchise()
        let voiceActingRating = try !isComingSoon ? site.getDetailsVoiceActingRating() : nil
        let watchAlsoMovies = try site.getDetailsWatchAlsoMovies()
        let commentsCount = try site.getCommentsCount()
        let adb = try site.getAdb()
        let type = try site.getType()
        let favs = try site.getFavs()

        var imdbRating: MovieRating?
        var kpRating: MovieRating?
        var releaseDate: String?
        var producer: [PersonSimple]?
        var ageRestriction: String?
        var actors: [PersonSimple]?
        var countries: [MovieCountry]?
        var genres: [MovieGenre]?
        var lists: [MovieList]?
        var collections: [MoviesCollection]?
        var duration: Int?
        var slogan: String?

        try content.getDetailsChunked { chunk in
            let chunkName = try chunk.getDetailsName()

            switch chunkName {
            case "Рейтинги":
                imdbRating = try MovieRating(
                    value: chunk.getDetailsImdbRating(),
                    votesCount: chunk.getDetailsImdbVotes(),
                    link: chunk.getDetailsImdbLink()
                )
                kpRating = try MovieRating(
                    value: chunk.getDetailsKpRating(),
                    votesCount: chunk.getDetailsKpVotes(),
                    link: chunk.getDetailsKpLink()
                )
            case "Дата выхода":
                releaseDate = try chunk.last().orThrow().text()
            case "Режиссер":
                producer = try chunk.getDetailsProducers()
            case "Возраст":
                ageRestriction = try chunk.getDetailsAgeRestriction()
            case "Страна":
                countries = try chunk.last().orThrow().getDetailsCountries()
            case "Жанр":
                genres = try chunk.last().orThrow().getDetailsGenres()
            case "Время":
                duration = try Int(chunk.last().orThrow().text().trimmingCharacters(in: .decimalDigits.inverted))
            case "Входит в списки":
                lists = try chunk.last().orThrow().getDetailsMovieLists()
            case "Из серии":
                collections = try chunk.last().orThrow().getDetailsMovieCollections()
            case "Слоган":
                slogan = try chunk.last().orThrow().text()
//            case "В переводе":
            default:
                if let act = try chunk.getDetailsActors() {
                    actors = act
                }
            }
        }

        return MovieDetailed(
            movieId: movieId,
            nameRussian: nameRussian,
            nameOriginal: nameOriginal,
            hposter: hposter,
            poster: poster,
            duration: duration,
            description: description,
            releaseDate: releaseDate,
            countries: countries,
            ageRestriction: ageRestriction,
            rated: rated,
            rating: rating,
            votes: votes,
            imdbRating: imdbRating,
            kpRating: kpRating,
            genres: genres,
            lists: lists,
            collections: collections,
            slogan: slogan,
            schedule: schedule,
            franchise: franchise,
            producer: producer,
            actors: actors,
            available: isAvailable,
            comingSoon: isComingSoon,
            favs: favs,
            adb: adb,
            type: type,
            voiceActing: voiceActing,
            series: series,
            voiceActingRating: voiceActingRating,
            watchAlsoMovies: watchAlsoMovies,
            commentsCount: commentsCount
        )
    }

    static func parseBookmarks(from: String) throws -> [Bookmark] {
        try SwiftSoup.parse(from).checker().getBookmarks()
    }

    static func parseTrailerId(from: String) throws -> String {
        try from.getTrailerId()
    }

    static func parseMovieVideo(from: String) throws -> MovieVideo {
        try from.getMovieVideo()
    }

    static func parseSeriesSeasons(from: String) throws -> [MovieSeason] {
        if let seasons = try? SwiftSoup.parse(from).getSeasons() {
            return seasons
        } else {
            guard let json = try? JSONSerialization.jsonObject(with: from.data(using: .utf8).orThrow(), options: .allowFragments) as? [String: Any] else {
                throw HDrezkaError.parseJson("json", "parseSeriesSeasons")
            }

            guard let s = json["seasons"] as? String, let seasons = try SwiftSoup.parse(s).body() else {
                throw HDrezkaError.parseJson("seasons", "parseSeriesSeasons")
            }

            guard let e = json["episodes"] as? String, let episodes = try SwiftSoup.parse(e).body() else {
                throw HDrezkaError.parseJson("episodes", "parseSeriesSeasons")
            }

            return try seasons
                .select(".b-simple_season__item")
                .map { season in
                    let seasonId = try season.attr("data-tab_id")

                    let seasonEpisodes = try episodes
                        .select(".b-simple_episode__item[data-season_id=\(seasonId)]")
                        .map { episode in
                            try MovieEpisode(
                                episodeId: episode.attr("data-episode_id"),
                                name: episode.text().trimmingCharacters(in: .decimalDigits.inverted).isEmpty ? episode.text() : episode.text().trimmingCharacters(in: .decimalDigits.inverted),
                                isSelected: episode.hasClass("active"),
                                url: episode.hasAttr("href") ? episode.attr("href").removeMirror() : nil
                            )
                        }

                    return try MovieSeason(
                        seasonId: seasonId,
                        name: season.text().trimmingCharacters(in: .decimalDigits.inverted).isEmpty ? season.text() : season.text().trimmingCharacters(in: .decimalDigits.inverted),
                        episodes: seasonEpisodes,
                        isSelected: season.hasClass("active"),
                        url: season.hasAttr("href") ? season.attr("href").removeMirror() : nil
                    )
                }
        }
    }

    static func parseComments(from: String) throws -> [Comment] {
        guard let json = try? JSONSerialization.jsonObject(with: from.data(using: .utf8).orThrow(), options: .allowFragments) as? [String: Any] else {
            throw HDrezkaError.parseJson("json", "parseComments")
        }

        guard let html = json["comments"] as? String else {
            return []
        }

        return try SwiftSoup.parse(html).getComments()
    }

    static func parseLikes(from: String) throws -> [Like] {
        try SwiftSoup.parse(from).getLikes()
    }
}

private extension Elements {
    func getDetailsName() throws -> String {
        try get(0).select("h2").text()
    }

    func getDetailsImdbRating() throws -> Float? {
        try Float(get(1).select(".b-post__info_rates.imdb .bold").first()?.text() ?? "")
    }

    func getDetailsImdbVotes() throws -> String? {
        try get(1).select(".b-post__info_rates.imdb i").first()?.text().shortNumber
    }

    func getDetailsImdbLink() throws -> String? {
        guard let base64 = try get(1).select(".b-post__info_rates.imdb a").first()?.attr("href").reversed().drop(while: { $0 == "/" }).reversed()
        else {
            return nil
        }

        return try String(String(base64).suffix(from: String(base64).range(of: "/help/", options: .backwards).orThrow().upperBound)).base64Decoded.removingPercentEncoding
    }

    func getDetailsKpLink() throws -> String? {
        guard let base64 = try get(1).select(".b-post__info_rates.kp a").first()?.attr("href").reversed().drop(while: { $0 == "/" }).reversed()
        else {
            return nil
        }

        return try String(String(base64).suffix(from: String(base64).range(of: "/help/", options: .backwards).orThrow().upperBound)).base64Decoded.removingPercentEncoding
    }

    func getDetailsKpRating() throws -> Float? {
        try Float(get(1).select(".b-post__info_rates.kp .bold").first()?.text() ?? "")
    }

    func getDetailsKpVotes() throws -> String? {
        try get(1).select(".b-post__info_rates.kp i").first()?.text().shortNumber
    }

    func getDetailsProducers() throws -> [PersonSimple] {
        try get(1)
            .select(".persons-list-holder").first().orThrow()
            .select(".item")
            .compactMap {
                guard try !$0.select("a").isEmpty() else { return nil }

                let link = try $0.select("a").attr("href").removeMirror()
                let name = try $0.select("a").text()
                let photo = try $0.select(".person-name-item").attr("data-photo")

                return PersonSimple(
                    personId: link,
                    name: name,
                    photo: photo == "null" ? "" : photo
                )
            }
    }

    func getDetailsAgeRestriction() throws -> String {
        try get(1).select("span").first().orThrow().text()
    }

    func getDetailsActors() throws -> [PersonSimple]? {
        try get(0)
            .select("div")
            .first()?
            .select(".item")
            .compactMap {
                guard try !$0.select("a").isEmpty() else { return nil }

                let link = try $0.select("a").attr("href").removeMirror()
                let name = try $0.select("a").text()
                let photo = try $0.select(".person-name-item").attr("data-photo")

                return PersonSimple(
                    personId: link,
                    name: name,
                    photo: photo == "null" ? "" : photo
                )
            }
    }
}

private extension Element {
    func getComment() throws -> (NSAttributedString, [Comment.Spoiler]) {
        try select(".title_spoiler").remove()

        for br in try select("br") {
            try br.replaceWith(TextNode("\n", nil))
        }

        let commentText: NSMutableAttributedString = .init()
        var spoilers: [Comment.Spoiler] = []

        func processElement(_ element: Element, _ styles: Set<Comment.TextStyles> = .init()) throws {
            var styles: Set<Comment.TextStyles> = styles

            switch element.tagName() {
            case "b":
                styles.insert(.bold)
            case "i":
                styles.insert(.italic)
            case "u":
                styles.insert(.underline)
            case "s":
                styles.insert(.strikethrough)
            case "a":
                try styles.insert(.link(element.attr("href")))
            case "div" where element.hasClass("text_spoiler"):
                try spoilers.append(.init(range: .init(location: commentText.length, length: element.text(trimAndNormaliseWhitespace: false).count)))
            default:
                break
            }

            for child in element.getChildNodes() {
                if let childElement = child as? Element {
                    try processElement(childElement, styles)
                } else if let childTextNode = child as? TextNode {
                    let text: String = if case .link = styles.first(where: {
                        if case .link = $0 {
                            true
                        } else {
                            false
                        }
                    }), let url = URL(string: childTextNode.getWholeText()), let host = url.host(), Const.mirror.host() == host, let redirectHost = Const.redirectMirror.host() {
                        childTextNode.getWholeText().replacingOccurrences(of: host, with: redirectHost)
                    } else {
                        childTextNode.getWholeText()
                    }

                    commentText.append(string: text) {
                        let link: String? = if case let .link(link) = styles.first(where: {
                            if case .link = $0 {
                                true
                            } else {
                                false
                            }
                        }), let url = URL(string: link) {
                            if let host = url.host(), Const.mirror.host() == host, let redirectHost = Const.redirectMirror.host() {
                                link.replacingOccurrences(of: host, with: redirectHost)
                            } else {
                                link
                            }
                        } else {
                            nil
                        }

                        $0.font(
                            bold: styles.contains(.bold),
                            italic: styles.contains(.italic),
                            underline: styles.contains(.underline),
                            strikethrough: styles.contains(.strikethrough),
                            link: link
                        )
                    }
                }
            }
        }

        for child in getChildNodes() {
            if let element = child as? Element {
                try processElement(element)
            } else if let textNode = child as? TextNode {
                commentText.append(string: textNode.getWholeText()) { $0.font() }
            }
        }

        return (commentText, spoilers)
    }

    func getComments(depth: Int = 0) throws -> [Comment] {
        try select(".comments-tree-item[data-indent=\"\(depth.description)\"]").map {
            let (text, spoilers) = try $0.select(".text").first().orThrow().getComment()

            return try Comment(
                commentId: $0.attr("data-id"),
                date: $0.select(".date").first().orThrow().text().replacingOccurrences(of: "оставлен ", with: ""),
                author: $0.select(".name").first().orThrow().text(),
                photo: $0.select("img").first().orThrow().attr("src"),
                text: text,
                spoilers: spoilers,
                replies: $0.getComments(depth: depth + 1),
                likesCount: Int($0.select(".b-comment__like_it").first()?.attr("data-likes_num") ?? "0").orThrow(),
                isLiked: $0.select(".b-comment__like_it").first()?.hasClass("disabled") == true,
                selfComment: $0.select(".b-comment__like_it").first()?.hasClass("self-disabled") == true,
                isAdmin: $0.select(".b-comment").first()?.hasClass("b-comment__admin") == true,
                deleteHash: $0.select(".actions").first()?.select(".edit li a").first(where: { try $0.text().contains("Удалить") })?.attr("onclick").components(separatedBy: "(").last?.components(separatedBy: ")").first?.components(separatedBy: ",").first(where: { $0.contains("'") })?.trimmingCharacters(in: .alphanumerics.inverted)
            )
        }
    }

    func getDetailsRussianName() throws -> String {
        try select(".b-post__title").first().orThrow().text()
    }

    func getDetailsOriginalName() throws -> String? {
        try select(".b-post__origtitle").first()?.text()
    }

    func getDetailsHPoster() throws -> String {
        try select(".b-sidecover a").first().orThrow().attr("href")
    }

    func getDetailsPoster() throws -> String {
        try select(".b-sidecover a img").first().orThrow().attr("src")
    }

    func isRatedDetails() throws -> Bool {
        try select(".b-post__rating .b-post__rating_wrapper").isEmpty()
    }

    func getDetailsRating() throws -> Float? {
        try Float(select(".b-post__rating .num").first()?.text() ?? "")
    }

    func getDetailsVotes() throws -> String? {
        try select(".b-post__rating .votes span").first()?.text().shortNumber
    }

    func getDetailsChunked(onGot: (Elements) throws -> Void) throws {
        try select(".b-post__info").first().orThrow()
            .select("tbody")
            .forEach { tr in
                for tableItem in try tr.select("tr") {
                    try tableItem.select("td").chunks(ofCount: 2).forEach { chunk in
                        try onGot(chunk.base)
                    }
                }
            }
    }

    func getDetailsCountries() throws -> [MovieCountry] {
        try select("a")
            .map {
                try MovieCountry(
                    name: $0.text(),
                    countryId: $0.attr("href").removeMirror()
                )
            }
    }

    func getDetailsGenres() throws -> [MovieGenre] {
        try select("a")
            .map {
                try MovieGenre(
                    name: $0.text(),
                    genreId: $0.attr("href").removeMirror()
                )
            }
    }

    func getDetailsMovieLists() throws -> [MovieList] {
        try html()
            .components(separatedBy: "<br />")
            .map {
                let listItem = try SwiftSoup.parse($0).body().orThrow()

                return try MovieList(
                    name: listItem.select("a").first().orThrow().text(),
                    listId: listItem.select("a").first().orThrow().attr("href").removeMirror(),
                    moviePosition: Int(listItem.text().components(separatedBy: "(").last?.trimmingCharacters(in: .decimalDigits.inverted) ?? "").orThrow()
                )
            }
    }

    func getDetailsMovieCollections() throws -> [MoviesCollection] {
        try select("a").map {
            try MoviesCollection(
                collectionId: $0.attr("href").removeMirror().replacingOccurrences(of: "collections/", with: ""),
                name: $0.text(),
                poster: nil,
                count: nil
            )
        }
    }

    func getDetailsDescription() throws -> String {
        try select(".b-post__description .b-post__description_text").first().orThrow().text()
    }
}

private extension Document {
    func getLikes() throws -> [Like] {
        try select(".b-comment__likescontent_inner li").map {
            let img = try $0.select("img").first().orThrow()

            return try Like(
                photo: img.attr("src"),
                name: img.attr("alt")
            )
        }
    }

    func getType() throws -> String? {
        try select("#type_id").first()?.val()
    }

    func getAdb() throws -> String? {
        try select("#has_adb").first()?.val()
    }

    func getFavs() throws -> String {
        try select("#ctrl_favs").first().orThrow().attr("value")
    }

    func getCommentsCount() throws -> Int {
        try Int(select("#comments-list-button em").text()) ?? 0
    }

    func getDetailsWatchAlsoMovies() throws -> [MovieSimple] {
        try select(".b-sidelist__holder .b-content__inline_item").map {
            try MovieSimple(
                movieId: $0.getId(),
                name: $0.getName(),
                details: $0.getDetails(),
                poster: $0.getPoster(),
                cat: $0.getCat(),
                info: $0.getInfo()
            )
        }
    }

    func getBookmarks() throws -> [Bookmark] {
        try select("#user-favorites-list .hd-label-row").map {
            let name = try $0.select("label").text().components(separatedBy: "(").dropLast().joined(separator: "(")
            let id = try Int($0.select("input").attr("value")).orThrow()
            let count = try Int($0.select("small b").text()).orThrow()
            let isChecked = try $0.select("input").hasAttr("checked")

            return Bookmark(bookmarkId: id, name: name, count: count, isChecked: isChecked, firstState: isChecked)
        }
    }

    func getDetailsVoiceActingRating() throws -> [MovieVoiceActingRating]? {
        guard let popup = try select(".b-rgstats__help").first() else {
            return nil
        }

        let items = try SwiftSoup.parse(Parser.unescapeEntities(popup.attr("title"), false)).body().orThrow().select(".inner")

        return try items.map {
            try MovieVoiceActingRating(
                name: $0.select(".title").text().addFlag($0.select("img").attr("src")),
                percent: Float($0.select(".count").text()
                    .trimmingCharacters(in: .decimalDigits.inverted)
                    .replacingOccurrences(of: ",", with: ".")
                ).orThrow()
            )
        }
    }

    func getDetailsContent() throws -> Element {
        try select(".b-content__main").first().orThrow()
    }

    func isAvailable() throws -> Bool {
        try !select(".b-player__container_cdn").isEmpty()
    }

    func isComingSoon() throws -> Bool {
        try !select(".b-post__status_logo").isEmpty()
    }

    func getSeasons() throws -> [MovieSeason]? {
        if try (select("#simple-seasons-tabs").isEmpty() && select("#simple-episodes-tabs").isEmpty()) {
            return nil
        }

        if try (select("#simple-seasons-tabs").isEmpty()) {
            let id = try select("[id*=\"simple-episodes-list\"] .b-simple_episode__item").first().orThrow().attr("data-season_id")

            let episodes = try select("#simple-episodes-list-\(id)").first().orThrow()
                .select(".b-simple_episode__item")
                .map { episode in
                    try MovieEpisode(
                        episodeId: episode.attr("data-episode_id"),
                        name: episode.text().trimmingCharacters(in: .decimalDigits.inverted).isEmpty ? episode.text() : episode.text().trimmingCharacters(in: .decimalDigits.inverted),
                        isSelected: episode.hasClass("active"),
                        url: episode.hasAttr("href") ? episode.attr("href").removeMirror() : nil
                    )
                }

            return [
                MovieSeason(
                    seasonId: id,
                    name: id.trimmingCharacters(in: .decimalDigits.inverted),
                    episodes: episodes,
                    isSelected: true,
                    url: nil
                )
            ]
        } else {
            return try select(".b-simple_season__item").map { season in
                let id = try season.attr("data-tab_id")
                let episodes = try select("#simple-episodes-list-\(id)").first().orThrow()
                    .select(".b-simple_episode__item")
                    .map { episode in
                        try MovieEpisode(
                            episodeId: episode.attr("data-episode_id"),
                            name: episode.text().trimmingCharacters(in: .decimalDigits.inverted).isEmpty ? episode.text() : episode.text().trimmingCharacters(in: .decimalDigits.inverted),
                            isSelected: episode.hasClass("active"),
                            url: episode.hasAttr("href") ? episode.attr("href").removeMirror() : nil
                        )
                    }

                return try MovieSeason(
                    seasonId: id,
                    name: season.text().trimmingCharacters(in: .decimalDigits.inverted).isEmpty ? season.text() : season.text().trimmingCharacters(in: .decimalDigits.inverted),
                    episodes: episodes,
                    isSelected: season.hasClass("active"),
                    url: season.hasAttr("href") ? season.attr("href").removeMirror() : nil
                )
            }
        }
    }

    func getDetailsVoiceActing(movieId: String) throws -> [MovieVoiceActing] {
        let translatorsList = try select("#translators-list")

        if !translatorsList.isEmpty() {
            return try translatorsList
                .select(".b-translator__item")
                .map {
                    try MovieVoiceActing(
                        name: $0.text().addFlag($0.select("img").attr("src")),
                        voiceId: movieId,
                        translatorId: $0.attr("data-translator_id"),
                        isCamrip: $0.attr("data-camrip"),
                        isAds: $0.attr("data-ads"),
                        isDirector: $0.attr("data-director"),
                        isPremium: $0.hasClass("b-prem_translator"),
                        isSelected: $0.hasClass("active"),
                        url: $0.hasAttr("href") ? $0.attr("href").removeMirror() : nil
                    )
                }
        } else {
            func getByOffset(offsetKey: String) throws -> [MovieVoiceActing] {
                let siteString = try html()
                guard let index = siteString.range(of: offsetKey) else {
                    throw HDrezkaError.parseJson("voice acting", "getByOffset")
                }
                let substring = String(siteString[index.lowerBound...])
                let translatorId = substring
                    .replacingOccurrences(of: "\(offsetKey)(\(movieId), ", with: "")
                let name = try select(".b-post__info").first().orThrow().select("tr").first(where: { try $0.select(".l").text().contains("В переводе") })?.select("td:not(.l)").text() ?? ""

                return try [
                    MovieVoiceActing(
                        name: name,
                        voiceId: movieId,
                        translatorId: String(translatorId[..<translatorId.firstIndex(of: ",").orThrow()]),
                        isCamrip: "",
                        isAds: "",
                        isDirector: "",
                        isPremium: false,
                        isSelected: true,
                        url: nil
                    )
                ]
            }

            return try (try? getByOffset(offsetKey: "initCDNMoviesEvents")) ?? getByOffset(offsetKey: "initCDNSeriesEvents")
        }
    }

    func getDetailsSchedule() throws -> [SeriesScheduleGroup]? {
        if try select(".b-post__schedule_block").isEmpty() {
            return nil
        }

        return try select(".b-post__schedule_block").map { block in
            let blockTitle = try block.select(".b-post__schedule_block_title .title").text()

            let items = try block
                .select("tr")
                .map { item in
                    let title = try item.select(".td-1").text()
                    let russianEpisodeName = try item.select(".td-2 b").text()
                    let originalEpisodeName = try item.select(".td-2 span").text().isEmpty ? nil : try item.select(".td-2 span").text()
                    let releaseDate = try item.select(".td-4").text()

                    return SeriesScheduleItem(
                        title: title,
                        russianEpisodeName: russianEpisodeName,
                        originalEpisodeName: originalEpisodeName,
                        releaseDate: releaseDate
                    )
                }
                .filter { !$0.title.isEmpty }

            return SeriesScheduleGroup(name: blockTitle, items: items)
        }
    }

    func getDetailsFranchise() throws -> [MovieFranchisePart]? {
        if try select(".b-post__partcontent_item").isEmpty() {
            return nil
        }

        return try select(".b-post__partcontent_item")
            .map { item in
                let name = try item.select(".td.title").text()
                let id = try item.getId()
                let year = try item.select(".td.year").text().trimmingCharacters(in: .decimalDigits.inverted)
                let rating = try Float(item.select(".td.rating").text())
                let current = item.hasClass("current")
                let position = try Int(item.select(".td.num").text()).orThrow()

                return MovieFranchisePart(
                    franchiseId: id,
                    name: name,
                    year: year,
                    rating: rating,
                    current: current,
                    position: position
                )
            }
            .filter { !$0.name.isEmpty }
    }
}

private extension String {
    func getTrailerId() throws -> String {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data(using: .utf8).orThrow(), options: .allowFragments) as? [String: Any] else {
            throw HDrezkaError.parseJson("json", "getTrailerLink")
        }

        guard let code = jsonObject["code"] as? String else {
            throw HDrezkaError.parseJson("code", "getTrailerLink")
        }

        let trailerId = try SwiftSoup.parse(code)
            .select("iframe").first().orThrow()
            .attr("src")
            .replacingOccurrences(of: "https://www.youtube.com/embed/", with: "")
            .components(separatedBy: "?").first.orThrow()

//        return "https://youtu.be/\(trailerId)"
//        return "https://www.youtube.com/watch?v=\(trailerId)"

        return trailerId
    }

    func getMovieVideo() throws -> MovieVideo {
        guard let jsonObject =
            (try? JSONSerialization.jsonObject(with: data(using: .utf8).orThrow(), options: .allowFragments) as? [String: Any]) ??
            range(of: "{\"id\":").flatMap({ startIndex in
                range(of: "});", range: startIndex.lowerBound ..< endIndex).flatMap { endIndex in
                    try? JSONSerialization.jsonObject(with: self[startIndex.lowerBound ... endIndex.lowerBound].data(using: .utf8).orThrow(), options: .allowFragments) as? [String: Any]
                }
            })
        else {
            throw HDrezkaError.parseJson("json", "getMovieVideo")
        }

        guard let url = (jsonObject["url"] as? String) ?? (jsonObject["streams"] as? String) else {
            if let message = jsonObject["message"] as? String, message.range(of: "необходимо авторизоваться", options: .caseInsensitive) != nil {
                throw HDrezkaError.loginRequired(Defaults[.mirror])
            } else {
                throw HDrezkaError.parseJson("url", "getMovieVideo")
            }
        }

        let streams = decrypt(encrypted: url)

        let videoMap = try streams.components(separatedBy: ",").reduce(into: OrderedDictionary<String, URL?>()) { videoMap, stream in
            let video = stream.replacingOccurrences(of: "[", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let name = try SwiftSoup.parse(video.components(separatedBy: "]").first.orThrow()).text()
            let videos = video[(video.lastIndex(of: "]") ?? video.startIndex)...].dropFirst().components(separatedBy: " or ")
            let link = videos.first?.components(separatedBy: ":hls:manifest.m3u8").first

            let url: URL? = if let link, link != "null" {
                URL(string: link)
            } else {
                nil
            }

            if let url, url.pathExtension != "mp4" || url.isFileURL {
                throw HDrezkaError.skipLink(url)
            }

            videoMap[name] = url
        }

        let subtitles: [MovieSubtitles] = if let subtitles = (jsonObject["subtitle"] as? String), let subtitles_lns = (jsonObject["subtitle_lns"] as? [String: Any]) {
            try subtitles.components(separatedBy: ",").compactMap {
                let name = try $0.components(separatedBy: "]").first.orThrow().replacingOccurrences(of: "[", with: "")
                let link = try $0.components(separatedBy: "]").last.orThrow()
                let lang = subtitles_lns[name] as? String

                if let lang {
                    return MovieSubtitles(
                        name: name,
                        link: link,
                        lang: lang
                    )
                } else {
                    return nil
                }
            }
        } else {
            []
        }

        return MovieVideo(
            videoMap: videoMap,
            subtitles: subtitles,
            needPremium: (jsonObject["premium_content"] as? Int ?? 0) == 1,
            thumbnails: jsonObject["thumbnails"] as? String
        )
    }

    func addFlag(_ link: String) -> String {
        if !link.isEmpty, let url = URL(string: link) {
            if url.lastPathComponent.contains("ua") {
                "\(self) \u{1F1FA}\u{1F1E6}"
            } else if url.lastPathComponent.contains("kz") {
                "\(self) \u{1F1F0}\u{1F1FF}"
            } else if url.lastPathComponent.contains("ru") {
                "\(self) \u{1F1F7}\u{1F1FA}"
            } else {
                self
            }
        } else {
            self
        }
    }
}

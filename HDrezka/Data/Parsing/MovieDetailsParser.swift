import Algorithms
import Defaults
import Foundation
import OrderedCollections
import SwiftSoup
import SwiftUI

class MovieDetailsParser {
    static func parseMovieDetails(from: String, movieId: String) throws -> MovieDetailed {
        let site = try from.parseHTML().checker()
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
        var waRating: MovieRating?
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
        var year: String?

        try content.getDetailsChunked { chunk in
            let chunkName = try chunk.getDetailsName()

            switch chunkName {
            case "Рейтинги":
                imdbRating = try chunk.getDetailsRating(of: "imdb")
                kpRating = try chunk.getDetailsRating(of: "kp")
                waRating = try chunk.getDetailsRating(of: "wa")
            case "Дата выхода":
                releaseDate = try chunk.last().orThrow().text()
            case "Год":
                year = try chunk.last().orThrow().text()
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
            waRating: waRating,
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
            commentsCount: commentsCount,
            year: year,
        )
    }

    static func parseBookmarks(from: String) throws -> [Bookmark] {
        try from.parseHTML().checker().getBookmarks()
    }

    static func parseTrailerId(code: String) throws -> String {
        try code.parseHTML()
            .select("iframe").first().orThrow()
            .attr("src")
            .substringAfter("https://www.youtube.com/embed/")
            .substringBefore("?")
    }

    static func parseMovieVideo(from: String) throws -> MovieVideo {
        try from.getMovieVideo()
    }

    static func parseSeriesSeasons(from: String) throws -> [MovieSeason] {
        guard let json = from.jsonObject else {
            guard let seasons = try from.parseHTML().getSeasons() else {
                throw HDrezkaError.parseJson("json", "parseSeriesSeasons")
            }

            return seasons
        }

        guard let seasonsString = json["seasons"] as? String, let seasons = try seasonsString.parseHTML().body() else {
            throw HDrezkaError.parseJson("seasons", "parseSeriesSeasons")
        }

        guard let episodeString = json["episodes"] as? String, let episodes = try episodeString.parseHTML().body() else {
            throw HDrezkaError.parseJson("episodes", "parseSeriesSeasons")
        }

        let episodesBySeason = try Dictionary(grouping: episodes.select(".b-simple_episode__item")) { try $0.attr("data-season_id") }

        return try seasons
            .select(".b-simple_season__item")
            .map { season in
                let seasonId = try season.attr("data-tab_id")

                return try MovieSeason(
                    seasonId: seasonId,
                    name: season.getNumberName(),
                    episodes: (episodesBySeason[seasonId] ?? []).map { try $0.getEpisode() },
                    isSelected: season.hasClass("active"),
                    url: season.attr("href").cleanPath,
                )
            }
    }

    static func parseComments(html: String?) throws -> [Comment] {
        guard let html else {
            return []
        }

        return try html.parseHTML().getComments()
    }

    static func parseLikes(from: String) throws -> [Like] {
        try from.parseHTML().getLikes()
    }
}

private extension Elements {
    func getDetailsName() throws -> String? {
        try select(".l").first()?.text().trimmingCharacters(in: .letters.inverted)
    }

    func getDetailsRating(of source: String) throws -> MovieRating? {
        guard let rates = try last()?.select(".b-post__info_rates.\(source)").first() else {
            return nil
        }

        let link = try rates.select("a").first()?.attr("href").substringBeforeLast("/").substringAfterLast("/").base64Decoded.removingPercentEncoding

        return try MovieRating(
            value: Float(rates.select(".bold").first()?.text() ?? ""),
            votesCount: rates.select("i").first()?.text().shortNumber,
            link: link,
        )
    }

    func getDetailsProducers() throws -> [PersonSimple] {
        try last().orThrow()
            .select(".persons-list-holder").first().orThrow()
            .select(".item")
            .getPersons()
    }

    func getDetailsAgeRestriction() throws -> String {
        try last().orThrow().select("span").first().orThrow().text()
    }

    func getDetailsActors() throws -> [PersonSimple]? {
        try first()?
            .select("div")
            .first()?
            .select(".item")
            .getPersons()
    }

    func getPersons() throws -> [PersonSimple] {
        try compactMap {
            let link = try $0.select("a")

            guard !link.isEmpty() else { return nil }

            let photo = try $0.select(".person-name-item").attr("data-photo")

            return try PersonSimple(
                personId: link.attr("href").cleanPath.orThrow(),
                name: link.text(),
                photo: photo == "null" ? "" : photo,
            )
        }
    }
}

private extension Element {
    func getNumberName() throws -> String {
        let text = try text()
        let number = text.trimmingCharacters(in: .decimalDigits.inverted)

        return number.isEmpty ? text : number
    }

    func getEpisode() throws -> MovieEpisode {
        try MovieEpisode(
            episodeId: attr("data-episode_id"),
            name: getNumberName(),
            isSelected: hasClass("active"),
            url: attr("href").cleanPath,
        )
    }

    func getComment() throws -> AttributedString {
        try select(".title_spoiler").remove()

        for br in try select("br") {
            try br.replaceWith(TextNode("\n", nil))
        }

        var commentText = AttributedString()

        func append(_ text: String, _ attributes: AttributeContainer = .init()) {
            commentText.append(AttributedString(text, attributes: attributes))
        }

        func processElement(_ element: Element, _ attributes: AttributeContainer = .init()) throws {
            var attributes = attributes

            switch element.tagName() {
            case "b":
                attributes.inlinePresentationIntent = (attributes.inlinePresentationIntent ?? []).union(.stronglyEmphasized)
            case "i":
                attributes.inlinePresentationIntent = (attributes.inlinePresentationIntent ?? []).union(.emphasized)
            case "u":
                attributes.swiftUI.underlineStyle = .single
            case "s":
                attributes.swiftUI.strikethroughStyle = .single
            case "a":
                attributes.link = try URL(string: element.attr("href").replacingMirrorHost)
            case "div" where element.hasClass("text_spoiler"):
                attributes[Comment.SpoilerKey.self] = UUID()
            default:
                break
            }

            for child in element.getChildNodes() {
                if let childElement = child as? Element {
                    try processElement(childElement, attributes)
                } else if let childTextNode = child as? TextNode {
                    let text = childTextNode.getWholeText()

                    append(attributes.link != nil ? text.replacingMirrorHost : text, attributes)
                }
            }
        }

        for child in getChildNodes() {
            if let element = child as? Element {
                try processElement(element)
            } else if let textNode = child as? TextNode {
                append(textNode.getWholeText())
            }
        }

        return commentText
    }

    func getComments(depth: Int = 0) throws -> [Comment] {
        try select(".comments-tree-item[data-indent=\"\(depth)\"]").map { item in
            let like = try item.select(".b-comment__like_it").first()

            return try Comment(
                commentId: item.attr("data-id"),
                date: item.select(".date").first().orThrow().text().replacingOccurrences(of: "оставлен ", with: ""),
                author: item.select(".name").first().orThrow().text(),
                photo: item.select("img").first().orThrow().attr("src"),
                text: item.select(".text").first().orThrow().getComment(),
                replies: item.getComments(depth: depth + 1),
                likesCount: Int(like?.attr("data-likes_num") ?? "0").orThrow(),
                isLiked: like?.hasClass("disabled") == true,
                selfComment: like?.hasClass("self-disabled") == true,
                isAdmin: item.select(".b-comment").first()?.hasClass("b-comment__admin") == true,
                deleteHash: item.getCommentDeleteHash(),
            )
        }
    }

    func getCommentDeleteHash() throws -> String? {
        try select(".actions").first()?
            .select(".edit li a")
            .first { try $0.text().contains("Удалить") }?
            .attr("onclick")
            .substringAfterLast("(")
            .substringBefore(")")
            .components(separatedBy: ",")
            .first { $0.contains("'") }?
            .trimmingCharacters(in: .alphanumerics.inverted)
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
                    countryId: $0.attr("href").cleanPath.orThrow(),
                )
            }
    }

    func getDetailsGenres() throws -> [MovieGenre] {
        try select("a")
            .map {
                try MovieGenre(
                    name: $0.text(),
                    genreId: $0.attr("href").cleanPath.orThrow(),
                )
            }
    }

    func getDetailsMovieLists() throws -> [MovieList] {
        try html()
            .components(separatedBy: "<br />")
            .filter { !$0.isEmpty }
            .map {
                let listItem = try $0.parseHTML().body().orThrow()

                return try MovieList(
                    name: listItem.select("a").first().orThrow().text(),
                    listId: listItem.select("a").first().orThrow().attr("href").cleanPath.orThrow(),
                    moviePosition: Int(listItem.text().substringAfterLast("(").trimmingCharacters(in: .decimalDigits.inverted)).orThrow(),
                )
            }
    }

    func getDetailsMovieCollections() throws -> [MoviesCollection] {
        try select("a").map {
            try MoviesCollection(
                collectionId: $0.attr("href").cleanPath.orThrow().replacingOccurrences(of: "collections/", with: ""),
                name: $0.text(),
                poster: nil,
                count: nil,
            )
        }
    }

    func getDetailsDescription() throws -> String {
        try select(".b-post__description .b-post__description_text").first().orThrow().text()
    }
}

private extension SwiftSoup.Document {
    func getLikes() throws -> [Like] {
        try select(".b-comment__likescontent_inner li").map {
            let img = try $0.select("img").first().orThrow()

            return try Like(
                photo: img.attr("src"),
                name: img.attr("alt"),
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
        try select(".b-sidelist__holder .b-content__inline_item").getMovies()
    }

    func getBookmarks() throws -> [Bookmark] {
        try select("#user-favorites-list .hd-label-row").map {
            let name = try $0.select("label").text().substringBeforeLast("(").trim()
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

        let items = try Parser.unescapeEntities(popup.attr("title"), false).parseHTML().body().orThrow().select(".inner")

        return try items.map {
            try MovieVoiceActingRating(
                name: $0.select(".title").text().addFlag($0.select("img").attr("src")),
                percent: Float($0.select(".count").text()
                    .trimmingCharacters(in: .decimalDigits.inverted)
                    .replacingOccurrences(of: ",", with: ".")).orThrow(),
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
        let hasSeasonsTabs = try !select("#simple-seasons-tabs").isEmpty()

        if !hasSeasonsTabs, try select("#simple-episodes-tabs").isEmpty() {
            return nil
        }

        var episodeLists: [String: Element] = [:]

        for list in try select("[id^=simple-episodes-list-]") {
            let id = list.id()

            if episodeLists[id] == nil {
                episodeLists[id] = list
            }
        }

        func episodes(of seasonId: String) throws -> [MovieEpisode] {
            try episodeLists["simple-episodes-list-\(seasonId)"].orThrow()
                .select(".b-simple_episode__item")
                .map { try $0.getEpisode() }
        }

        if !hasSeasonsTabs {
            let id = try select("[id*=\"simple-episodes-list\"] .b-simple_episode__item").first().orThrow().attr("data-season_id")

            return try [
                MovieSeason(
                    seasonId: id,
                    name: id.trimmingCharacters(in: .decimalDigits.inverted),
                    episodes: episodes(of: id),
                    isSelected: true,
                    url: nil,
                ),
            ]
        } else {
            return try select(".b-simple_season__item").map { season in
                let id = try season.attr("data-tab_id")

                return try MovieSeason(
                    seasonId: id,
                    name: season.getNumberName(),
                    episodes: episodes(of: id),
                    isSelected: season.hasClass("active"),
                    url: season.attr("href").cleanPath,
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
                        url: $0.attr("href").cleanPath,
                    )
                }
        } else {
            let siteString = try html()

            func getByOffset(offsetKey: String) throws -> [MovieVoiceActing] {
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
                        url: nil,
                    ),
                ]
            }

            return try (try? getByOffset(offsetKey: "initCDNMoviesEvents")) ?? getByOffset(offsetKey: "initCDNSeriesEvents")
        }
    }

    func getDetailsSchedule() throws -> [SeriesScheduleGroup]? {
        let blocks = try select(".b-post__schedule_block")

        guard !blocks.isEmpty() else {
            return nil
        }

        return try blocks.map { block in
            let blockTitle = try block.select(".b-post__schedule_block_title .title").text()

            let items = try block
                .select("tr")
                .map { item in
                    let originalEpisodeName = try item.select(".td-2 span").text()

                    return try SeriesScheduleItem(
                        title: item.select(".td-1").text(),
                        russianEpisodeName: item.select(".td-2 b").text(),
                        originalEpisodeName: originalEpisodeName.isEmpty ? nil : originalEpisodeName,
                        releaseDate: item.select(".td-4").text(),
                    )
                }
                .filter { !$0.title.isEmpty }

            return SeriesScheduleGroup(name: blockTitle, items: items)
        }
    }

    func getDetailsFranchise() throws -> [MovieFranchisePart]? {
        let parts = try select(".b-post__partcontent_item")

        guard !parts.isEmpty() else {
            return nil
        }

        return try parts
            .map { item in
                let name = try item.select(".td.title").text()
                let id = try item.attr("data-url").cleanPath
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
                    position: position,
                )
            }
            .filter { !$0.name.isEmpty }
    }
}

private extension String {
    func getMovieVideo() throws -> MovieVideo {
        guard let jsonObject = self.jsonObject ?? substringAfter("{\"id\":", includeSeparator: true).substringBefore("); });").jsonObject else {
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

        let videos = try streams.components(separatedBy: ",").filter { !$0.isEmpty }.map { stream in
            let nameElement = try stream.substringAfter("[").substringBefore("]").parseHTML()
            let name = try nameElement.text()
            let videos = stream.substringAfter("]").components(separatedBy: " or ").filter { !$0.isEmpty }
            let links = videos.map { $0.substringBeforeLast(".mp4", includeSeparator: true) }.uniqued().filter { $0 != "null" }.compactMap { URL(string: $0) }

            if links.contains(where: { $0.pathExtension != "mp4" || $0.isFileURL }) {
                throw HDrezkaError.skipLinks(links)
            }

            return try MovieVideo.Video(quality: name, urls: links, needAccount: links.isEmpty, needPremium: !nameElement.select("img").isEmpty())
        }

        let subtitles: [MovieSubtitles] = if let subtitles = (jsonObject["subtitle"] as? String), let subtitlesLns = (jsonObject["subtitle_lns"] as? [String: Any]) {
            subtitles.components(separatedBy: ",").filter { !$0.isEmpty }.compactMap {
                let name = $0.substringAfter("[").substringBefore("]")
                let link = $0.substringAfter("]")
                let lang = subtitlesLns[name] as? String

                if let lang {
                    return MovieSubtitles(
                        name: name,
                        link: link,
                        lang: lang,
                    )
                } else {
                    return nil
                }
            }
        } else {
            []
        }

        return MovieVideo(
            videos: videos,
            subtitles: subtitles,
            needPremium: (jsonObject["premium_content"] as? Int ?? 0) == 1,
            thumbnails: jsonObject["thumbnails"] as? String,
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

private extension String {
    var replacingMirrorHost: String {
        guard let host = URL(string: self)?.host(),
              host == Const.mirror.host(),
              let redirectHost = Const.redirectMirror.host()
        else {
            return self
        }

        return replacingOccurrences(of: host, with: redirectHost)
    }
}

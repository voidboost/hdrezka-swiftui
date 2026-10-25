import Foundation
import SwiftSoup

class PeopleParser {
    static func parse(from: String) throws -> PersonDetailed {
        let site = try from.parseHTML().checker()
        let details = try site.getPeopleDetails()
        let movies = try site.getPeopleMovies()

        return try PersonDetailed(
            nameRu: site.getPeopleNameRussian(),
            nameOrig: site.getPeopleNameOriginal(),
            hphoto: site.getPeopleHPhoto(),
            photo: site.getPeoplePhoto(),
            career: details["Карьера"],
            birthDate: details["Дата рождения"],
            birthPlace: details["Место рождения"],
            deathDate: details["Дата смерти"],
            deathPlace: details["Место смерти"],
            height: details["Рост"],
            actorMovies: movies["akter"]?.getMovies(),
            actressMovies: movies["aktrisa"]?.getMovies(),
            directorMovies: movies["rezhisser"]?.getMovies(),
            producerMovies: movies["prodyuser"]?.getMovies(),
            screenwriterMovies: movies["scenarist"]?.getMovies(),
            operatorMovies: movies["operator"]?.getMovies(),
            editorMovies: movies["montazher"]?.getMovies(),
            artistMovies: movies["hudozhnik"]?.getMovies(),
            composerMovies: movies["kompozitor"]?.getMovies(),
        )
    }
}

private extension Document {
    func getPeopleNameRussian() throws -> String {
        try select(".b-post__title .t1").text()
    }

    func getPeopleNameOriginal() throws -> String? {
        let span = try select(".b-post__title .t2")

        return span.isEmpty() ? nil : try span.text()
    }

    func getPeopleSidecover() throws -> Element {
        try select(".b-post__infotable_left .b-sidecover").first().orThrow()
    }

    func getPeopleHPhoto() throws -> String {
        try getPeopleSidecover().select("a").attr("href")
    }

    func getPeoplePhoto() throws -> String {
        try getPeopleSidecover().select("img").attr("src")
    }

    func getPeopleDetails() throws -> [String: String] {
        var details: [String: String] = [:]

        for tr in try select(".b-post__infotable_right_inner tr") {
            let td = try tr.select("td")

            if td.count == 2 {
                try details[td.first().orThrow().select("h2").text()] = td.last().orThrow().text()
            }
        }

        return details
    }

    func getPeopleMovies() throws -> [String: Elements] {
        var movies: [String: Elements] = [:]

        for career in try select(".b-person__career") {
            try movies[career.select("h2").attr("id")] = career.select(".b-content__inline_item")
        }

        return movies
    }
}

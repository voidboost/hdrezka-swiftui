import Foundation
import SwiftSoup

class PeopleParser {
    static func parse(from site: Document) throws -> PersonDetailed {
        let details = try site.getPeopleDetails()

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
            filmography: site.getPeopleFilmography(),
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

    func getPeopleFilmography() throws -> [PersonDetailed.Career] {
        var sections: [PersonDetailed.Role: Elements] = [:]

        for career in try select(".b-person__career") {
            if let role = try PersonDetailed.Role(sectionId: career.select("h2").attr("id")) {
                sections[role] = try career.select(".b-content__inline_item")
            }
        }

        return try PersonDetailed.Role.allCases.compactMap { role in
            guard let movies = try sections[role]?.getMovies(), !movies.isEmpty else { return nil }

            return PersonDetailed.Career(role: role, movies: movies)
        }
    }
}

private extension PersonDetailed.Role {
    init?(sectionId: String) {
        switch sectionId {
        case "akter":
            self = .actor
        case "aktrisa":
            self = .actress
        case "hudozhnik":
            self = .artist
        case "rezhisser":
            self = .director
        case "montazher":
            self = .editor
        case "operator":
            self = .operator
        case "prodyuser":
            self = .producer
        case "scenarist":
            self = .screenwriter
        case "kompozitor":
            self = .composer
        default:
            return nil
        }
    }
}

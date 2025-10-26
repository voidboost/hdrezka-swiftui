import Foundation
import SwiftSoup

class PeopleParser {
    static func parse(from: String) throws -> PersonDetailed {
        let site = try SwiftSoup.parse(from).checker()

        let nameRussian = try site.getPeopleNameRussian()
        let nameOriginal = try site.getPeopleNameOriginal()
        let hphoto = try site.getPeopleHPhoto()
        let photo = try site.getPeoplePhoto()

        var career: String?
        var birthDate: String?
        var birthPlace: String?
        var deathDate: String?
        var deathPlace: String?
        var height: String?

        try site.getPeopleDetails { name, value in
            switch name {
            case "Карьера":
                career = value
            case "Дата рождения":
                birthDate = value
            case "Место рождения":
                birthPlace = value
            case "Дата смерти":
                deathDate = value
            case "Место смерти":
                deathPlace = value
            case "Рост":
                height = value
            default:
                break
            }
        }

        var actorMovies: [MovieSimple]?
        var actressMovies: [MovieSimple]?
        var directorMovies: [MovieSimple]?
        var producerMovies: [MovieSimple]?
        var screenwriterMovies: [MovieSimple]?
        var operatorMovies: [MovieSimple]?
        var editorMovies: [MovieSimple]?
        var artistMovies: [MovieSimple]?
        var composerMovies: [MovieSimple]?

        try site.getPeopleMovies { name, value in
            switch name {
            case "rezhisser":
                directorMovies = try value.getMovies()
            case "akter":
                actorMovies = try value.getMovies()
            case "prodyuser":
                producerMovies = try value.getMovies()
            case "scenarist":
                screenwriterMovies = try value.getMovies()
            case "operator":
                operatorMovies = try value.getMovies()
            case "montazher":
                editorMovies = try value.getMovies()
            case "hudozhnik":
                artistMovies = try value.getMovies()
            case "aktrisa":
                actressMovies = try value.getMovies()
            case "kompozitor":
                composerMovies = try value.getMovies()
            default:
                break
            }
        }

        return PersonDetailed(
            nameRu: nameRussian,
            nameOrig: nameOriginal,
            hphoto: hphoto,
            photo: photo,
            career: career,
            birthDate: birthDate,
            birthPlace: birthPlace,
            deathDate: deathDate,
            deathPlace: deathPlace,
            height: height,
            actorMovies: actorMovies,
            actressMovies: actressMovies,
            directorMovies: directorMovies,
            producerMovies: producerMovies,
            screenwriterMovies: screenwriterMovies,
            operatorMovies: operatorMovies,
            editorMovies: editorMovies,
            artistMovies: artistMovies,
            composerMovies: composerMovies,
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

    func getPeopleHPhoto() throws -> String {
        try select(".b-post__infotable_left .b-sidecover").first().orThrow().select("a").attr("href")
    }

    func getPeoplePhoto() throws -> String {
        try select(".b-post__infotable_left .b-sidecover").first().orThrow().select("img").attr("src")
    }

    func getPeopleDetails(onGot: (String, String) -> Void) throws {
        try select(".b-post__infotable_right_inner tr")
            .forEach { tr in
                let td = try tr.select("td")

                if td.count == 2 {
                    let name = try td.first().orThrow().select("h2").text()
                    let value = try td.last().orThrow().text()
                    onGot(name, value)
                }
            }
    }

    func getPeopleMovies(onGot: (String, Elements) throws -> Void) throws {
        try select(".b-person__career").forEach {
            let name = try $0.select("h2").attr("id")
            let movies = try $0.select(".b-content__inline_item")
            try onGot(name, movies)
        }
    }
}

private extension Elements {
    func getMovies() throws -> [MovieSimple] {
        try map {
            try MovieSimple(
                movieId: $0.getId(),
                name: $0.getName(),
                details: $0.getDetails(),
                poster: $0.getPoster(),
                cat: $0.getCat(),
                info: $0.getInfo(),
            )
        }
    }
}

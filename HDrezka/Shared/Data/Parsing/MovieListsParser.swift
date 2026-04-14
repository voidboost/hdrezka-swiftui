import Defaults
import Foundation
import SwiftSoup

class MovieListsParser {
    static func parse(from: String) throws -> (String, [MovieSimple]) {
        let site = try SwiftSoup.parseHTML(from, Defaults[.mirror].absoluteString)
            .checker()

        return try (
            site.select(".b-content__htitle").text(),
            site.getMovies()
                .map { movie in
                    let id = try movie.getId()
                    let name = try movie.getName()
                    let details = try movie.getDetails()
                    let poster = try movie.getPoster()
                    let cat = try movie.getCat()
                    let info = try movie.getInfo()

                    return MovieSimple(movieId: id, name: name, details: details, poster: poster, cat: cat, info: info)
                },
        )
    }

    static func parseHotMovies(from: String) throws -> [MovieSimple] {
        try SwiftSoup.parseHTML(from, Defaults[.mirror].absoluteString)
            .getMovies()
            .map { movie in
                let id = try movie.getId()
                let name = try movie.getName()
                let details = try movie.getDetails()
                let poster = try movie.getPoster()
                let cat = try movie.getCat()
                let info = try movie.getInfo()

                return MovieSimple(movieId: id, name: name, details: details, poster: poster, cat: cat, info: info)
            }
    }
}

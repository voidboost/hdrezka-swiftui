import Foundation
import SwiftSoup

class SearchParser {
    static func parseSearch(from: String) throws -> [MovieSimple] {
        try SwiftSoup.parse(from)
            .checker()
            .getMovies()
            .map { movie in
                try MovieSimple(
                    movieId: movie.getId(),
                    name: movie.getName(),
                    details: movie.getDetails(),
                    poster: movie.getPoster(),
                    cat: movie.getCat(),
                    info: movie.getInfo(),
                )
            }
    }

    static func parseCategories(from: String) throws -> [MovieType] {
        try SwiftSoup.parse(from)
            .checker()
            .getTypes()
            .map { type in
                try MovieType(
                    name: type.getTypeName(),
                    typeId: type.getTypeId(),
                    genres: type.getTypeGenres(),
                    best: type.getTypeBest(),
                )
            }
    }
}

private extension Document {
    func getTypes() throws -> Elements {
        try select(".b-topnav__item:not(.single)")
    }
}

private extension Element {
    func getTypeId() throws -> String {
        try select(".b-topnav__item-link").first().orThrow().attr("href").cleanPath.orThrow()
    }

    func getTypeName() throws -> String {
        try select(".b-topnav__item-link").first().orThrow().text()
    }

    func getTypeGenres() throws -> [MovieGenre] {
        try select(".b-topnav__sub .left").first().orThrow()
            .select("li a")
            .map {
                let name = try $0.text()
                let id = try $0.attr("href").cleanPath.orThrow()

                return MovieGenre(
                    name: name,
                    genreId: id,
                )
            }
    }

    func getTypeBest() throws -> MovieBest {
        let best = try select(".b-topnav__sub .b-topnav__findbest_block").first().orThrow()

        let name = best.ownText()

        let genres = try best.select(".select-category").first().orThrow()
            .select("option")
            .map {
                let name = try $0.text()
                let id = try $0.attr("value").cleanPath.orThrow()

                return MovieGenre(
                    name: name,
                    genreId: id,
                )
            }

        let years = try best.select(".select-year").first().orThrow()
            .select("option")
            .compactMap {
                let name = try $0.text()
                let year = try Int($0.attr("value"))

                if let year {
                    return MovieYear(
                        name: name,
                        year: year,
                    )
                } else {
                    return nil
                }
            }

        return MovieBest(
            name: name,
            genres: genres,
            years: years,
        )
    }
}

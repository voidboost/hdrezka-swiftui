import Foundation
import SwiftSoup

class MovieListsParser {
    static func parse(from: String) throws -> (String, [MovieSimple]) {
        let site = try from.parseHTML().checker()

        return try (site.select(".b-content__htitle").text(), site.getMovies())
    }

    static func parseMovies(from: String) throws -> [MovieSimple] {
        try from.parseHTML().checker().getMovies()
    }

    static func parseHotMovies(from: String) throws -> [MovieSimple] {
        try from.parseHTML().getMovies()
    }
}

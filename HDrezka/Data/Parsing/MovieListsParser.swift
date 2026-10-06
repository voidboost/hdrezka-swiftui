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
                .map { try $0.getMovie() },
        )
    }

    static func parseHotMovies(from: String) throws -> [MovieSimple] {
        try SwiftSoup.parseHTML(from, Defaults[.mirror].absoluteString)
            .getMovies()
            .map { try $0.getMovie() }
    }
}

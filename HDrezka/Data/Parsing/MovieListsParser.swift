import Foundation
import SwiftSoup

class MovieListsParser {
    static func parse(from site: Document) throws -> (String, [MovieSimple]) {
        try (site.select(".b-content__htitle").text(), site.getMovies())
    }

    static func parseMovies(from site: Document) throws -> [MovieSimple] {
        try site.getMovies()
    }

    static func parseHotMovies(from: String) throws -> [MovieSimple] {
        try from.parseHTML().getMovies()
    }
}

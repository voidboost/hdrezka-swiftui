import Defaults
import Foundation
import SwiftSoup

class CollectionsParser {
    static func parseCollections(from: String) throws -> [MoviesCollection] {
        try SwiftSoup.parseHTML(from, Defaults[.mirror].absoluteString)
            .checker()
            .getCollections()
            .map { collection in
                try MoviesCollection(
                    collectionId: collection.getCollectionId(),
                    name: collection.getCollectionName(),
                    poster: collection.getCollectionPoster(),
                    count: collection.getCollectionCountOfMovies(),
                )
            }
    }

    static func parseMoviesInCollection(from: String) throws -> [MovieSimple] {
        try SwiftSoup.parseHTML(from, Defaults[.mirror].absoluteString)
            .checker()
            .getMovies()
            .map { try $0.getMovie() }
    }
}

private extension Document {
    func getCollections() throws -> Elements {
        try select(".b-content__collections_item")
    }
}

private extension Element {
    func getCollectionName() throws -> String {
        try select(".title-layer a").first().orThrow().text()
    }

    func getCollectionPoster() throws -> String {
        try select("img").first().orThrow().attr("src")
    }

    func getCollectionCountOfMovies() throws -> Int {
        try Int(select(".num.hd-tooltip").first().orThrow().text()).orThrow()
    }

    func getCollectionId() throws -> String {
        try attr("data-url").cleanPath.orThrow().replacingOccurrences(of: "collections/", with: "")
    }
}

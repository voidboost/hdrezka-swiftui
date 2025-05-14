import Foundation
import SwiftSoup

class CollectionsParser {
    static func parseCollections(from: String) throws -> [MoviesCollection] {
        try SwiftSoup.parse(from)
            .checker()
            .getCollections()
            .map { collection in
                try MoviesCollection(
                    collectionId: collection.getCollectionId(),
                    name: collection.getCollectionName(),
                    poster: collection.getCollectionPoster(),
                    count: collection.getCollectionCountOfMovies()
                )
            }
    }

    static func parseMoviesInCollection(from: String) throws -> [MovieSimple] {
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
                    info: movie.getInfo()
                )
            }
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
        try attr("data-url").removeMirror().replacingOccurrences(of: "collections/", with: "")
    }
}

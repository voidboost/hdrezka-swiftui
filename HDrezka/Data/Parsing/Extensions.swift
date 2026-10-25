import Defaults
import Foundation
import SwiftSoup

extension String {
    func parseHTML() throws -> Document {
        try SwiftSoup.parseHTML(self, Defaults[.mirror].absoluteString)
    }

    var jsonObject: [String: Any]? {
        guard let data = data(using: .utf8) else { return nil }

        return try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any]
    }
}

extension Document {
    func getMovies() throws -> [MovieSimple] {
        try select(".b-content__inline_item").getMovies()
    }
}

extension Elements {
    func getMovies() throws -> [MovieSimple] {
        try map { try $0.getMovie() }
    }
}

extension Element {
    func getMovie() throws -> MovieSimple {
        let cover = try select(".b-content__inline_item-cover a").first().orThrow()

        return try MovieSimple(
            movieId: getId(),
            name: getName(),
            details: getDetails(),
            poster: cover.getPoster(),
            cat: cover.getCat(),
            info: cover.getInfo(),
        )
    }

    private func getId() throws -> String {
        try attr("data-url").cleanPath.orThrow()
    }

    private func getName() throws -> String {
        try select(".b-content__inline_item-link a").first().orThrow().text()
    }

    private func getDetails() throws -> String {
        try select(".b-content__inline_item-link div").first().orThrow().text()
    }

    private func getPoster() throws -> String {
        try select("img").first().orThrow().attr("src")
    }

    private func getCat() throws -> MovieSimple.Cat? {
        let span = try select(".cat").first().orThrow()

        let rating = try Float(span.select(".b-category-bestrating").first()?.text().trimmingCharacters(in: .decimalDigits.inverted) ?? "")

        return switch try span.classNames().last.orThrow() {
        case "films":
            .film(rating)
        case "series":
            .series(rating)
        case "animation":
            .anime(rating)
        case "cartoons":
            .cartoon(rating)
        case "show":
            .show(rating)
        default:
            nil
        }
    }

    private func getInfo() throws -> MovieSimple.Info? {
        let info = try select(".info").first()?.html() ?? ""

        if info.contains("Завершен") {
            return .completed
        } else if info.contains("В ожидании") {
            return .wait
        } else if info.contains("сезон"), info.contains("серия") {
            let parts = info.components(separatedBy: info.contains(",") ? ", " : "<br />").filter { !$0.isEmpty }

            if parts.count == 2,
               let season = Int(parts[0].trimmingCharacters(in: .decimalDigits.inverted)),
               let episode = Int(parts[1].trimmingCharacters(in: .decimalDigits.inverted))
            {
                return .series(season, episode)
            }
        }

        return nil
    }
}

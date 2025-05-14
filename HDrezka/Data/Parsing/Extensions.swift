import Foundation
import SwiftSoup

extension Document {
    func getMovies() throws -> Elements {
        try select(".b-content__inline_item")
    }
}

extension Element {
    func getId() throws -> String {
        try attr("data-url").removeMirror()
    }

    func getName() throws -> String {
        try select(".b-content__inline_item-link a").first().orThrow().text()
    }

    func getDetails() throws -> String {
        try select(".b-content__inline_item-link div").first().orThrow().text()
    }

    func getPoster() throws -> String {
        try select(".b-content__inline_item-cover a img").first().orThrow().attr("src")
    }

    func getCat() throws -> MovieSimple.Cat? {
        let span = try select(".b-content__inline_item-cover a .cat").first().orThrow()

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

    func getInfo() throws -> MovieSimple.Info? {
        let info = try select(".b-content__inline_item-cover a").first().orThrow().select(".info").first()?.html() ?? ""

        if info.contains("Завершен") {
            return .completed
        } else if info.contains("В ожидании") {
            return .wait
        } else if info.contains("сезон"), info.contains("серия") {
            let parts = info.contains(",") ? info.components(separatedBy: ", ") : info.components(separatedBy: "<br />")

            if parts.count == 2 {
                let season = Int(parts[0].trimmingCharacters(in: .decimalDigits.inverted))

                let episode = Int(parts[1].trimmingCharacters(in: .decimalDigits.inverted))

                if let season, let episode {
                    return .series(season, episode)
                }
            }
        }

        return nil
    }
}

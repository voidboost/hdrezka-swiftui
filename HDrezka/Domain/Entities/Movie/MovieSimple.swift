import SwiftUI

struct MovieSimple: Identifiable, Codable, Hashable {
    let movieId: String
    let name: String?
    let details: String?
    let poster: String?
    let cat: Cat?
    let info: Info?
    let id: UUID

    init(movieId: String, name: String? = nil, details: String? = nil, poster: String? = nil, cat: Cat? = nil, info: Info? = nil, id: UUID = .init()) {
        self.movieId = movieId
        self.name = name
        self.details = details
        self.poster = poster
        self.cat = cat
        self.info = info
        self.id = id
    }
}

extension MovieSimple: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: MovieSimple.self, contentType: .json)
    }
}

extension MovieSimple {
    enum Cat: Codable, Hashable {
        case film(Float? = nil)
        case series(Float? = nil)
        case anime(Float? = nil)
        case cartoon(Float? = nil)
        case show(Float? = nil)

        var title: String {
            switch self {
            case .film:
                String(localized: "key.genre.film")
            case .series:
                String(localized: "key.genre.series")
            case .anime:
                String(localized: "key.genre.anime")
            case .cartoon:
                String(localized: "key.genre.cartoon")
            case .show:
                String(localized: "key.genre.show")
            }
        }

        var rating: Float? {
            switch self {
            case let .film(rating):
                rating
            case let .series(rating):
                rating
            case let .anime(rating):
                rating
            case let .cartoon(rating):
                rating
            case let .show(rating):
                rating
            }
        }

        var icon: String {
            switch self {
            case .film:
                "movieclapper"
            case .series:
                "play.rectangle.on.rectangle"
            case .anime:
                "film"
            case .cartoon:
                "paintbrush"
            case .show:
                "tv"
            }
        }

        var color: Color {
            switch self {
            case .anime:
                .gray
            case .film:
                .blue
            case .series:
                .red
            case .cartoon:
                .purple
            case .show:
                .orange
            }
        }
    }

    enum Info: Codable, Hashable {
        case completed
        case series(Int, Int)
        case wait

        var title: String {
            switch self {
            case .completed:
                String(localized: "key.completed")
            case let .series(season, episode):
                String(localized: "key.season-\(season).episode-\(episode)")
            case .wait:
                String(localized: "key.waiting_release")
            }
        }
    }
}

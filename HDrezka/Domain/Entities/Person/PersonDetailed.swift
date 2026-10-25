import Foundation

struct PersonDetailed: Identifiable, Hashable {
    let nameRu: String
    let nameOrig: String?
    let hphoto: String
    let photo: String
    let career: String?
    let birthDate: String?
    let birthPlace: String?
    let deathDate: String?
    let deathPlace: String?
    let height: String?
    let filmography: [Career]
    var id = UUID()
}

extension PersonDetailed {
    struct Career: Identifiable, Hashable {
        let role: Role
        let movies: [MovieSimple]

        var id: Role {
            role
        }
    }

    enum Role: CaseIterable, Hashable {
        case actor
        case actress
        case artist
        case director
        case editor
        case `operator`
        case producer
        case screenwriter
        case composer

        var title: String {
            switch self {
            case .actor:
                String(localized: "key.person.actor")
            case .actress:
                String(localized: "key.person.actress")
            case .artist:
                String(localized: "key.person.artist")
            case .director:
                String(localized: "key.person.director")
            case .editor:
                String(localized: "key.person.editor")
            case .operator:
                String(localized: "key.person.operator")
            case .producer:
                String(localized: "key.person.producer")
            case .screenwriter:
                String(localized: "key.person.screenwriter")
            case .composer:
                String(localized: "key.person.composer")
            }
        }
    }
}

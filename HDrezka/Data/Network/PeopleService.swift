import Foundation

enum PeopleService {
    case getPersonDetails(id: String)
}

extension PeopleService: Endpoint {
    var path: String {
        switch self {
        case let .getPersonDetails(id):
            "person/\(id)"
        }
    }
}

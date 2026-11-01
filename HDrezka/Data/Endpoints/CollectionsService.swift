import Alamofire
import Foundation

enum CollectionsService {
    case getCollections(page: Int)
    case getMoviesInCollectionWithFilter(collectionId: String, page: Int, filter: String)
}

extension CollectionsService: Endpoint {
    var path: String {
        switch self {
        case let .getCollections(page):
            "collections/".page(page)
        case let .getMoviesInCollectionWithFilter(collectionId, page, _):
            "collections/\(collectionId)/".page(page)
        }
    }

    func encode(_ request: URLRequest) throws -> URLRequest {
        switch self {
        case .getCollections:
            request
        case let .getMoviesInCollectionWithFilter(_, _, filter):
            try request.query(["filter": filter])
        }
    }
}

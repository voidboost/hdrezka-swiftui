import Alamofire
import Defaults
import Foundation

enum CollectionsService {
    case getCollections(page: Int)
    case getMoviesInCollectionWithFilter(collectionId: String, page: Int, filter: String)
}

extension CollectionsService: URLRequestConvertible {
    var baseURL: URL { Defaults[.mirror] }

    var path: String {
        switch self {
        case let .getCollections(page):
            "collections/".page(page)
        case let .getMoviesInCollectionWithFilter(collectionId, page, _):
            "collections/\(collectionId)/".page(page)
        }
    }

    var method: HTTPMethod { .get }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appending(path: path, directoryHint: .notDirectory)

        var request = URLRequest(url: url)
        request.method = method
        request.headers = Const.headers

        switch self {
        case let .getMoviesInCollectionWithFilter(_, _, filter):
            return try URLEncoding.queryString.encode(request, with: ["filter": filter])
        default:
            return request
        }
    }
}

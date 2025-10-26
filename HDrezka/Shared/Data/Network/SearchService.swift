import Alamofire
import Defaults
import Foundation

enum SearchService {
    case search(query: String, page: Int)
    case categories
}

extension SearchService: URLRequestConvertible {
    var baseURL: URL { Defaults[.mirror] }

    var path: String {
        switch self {
        case .search:
            "search/"
        case .categories:
            ""
        }
    }

    var method: HTTPMethod { .get }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appending(path: path, directoryHint: .notDirectory)

        var request = URLRequest(url: url)
        request.method = method
        request.headers = Const.headers

        switch self {
        case let .search(query, page):
            return try URLEncoding.queryString.encode(request, with: ["do": "search", "subaction": "search", "q": query, "page": page])
        default:
            return request
        }
    }
}

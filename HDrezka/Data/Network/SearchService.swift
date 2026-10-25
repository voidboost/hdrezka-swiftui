import Foundation

enum SearchService {
    case search(query: String, page: Int)
    case categories
}

extension SearchService: Endpoint {
    var path: String {
        switch self {
        case .search:
            "search/"
        case .categories:
            ""
        }
    }

    func encode(_ request: URLRequest) throws -> URLRequest {
        switch self {
        case let .search(query, page):
            try request.query(["do": "search", "subaction": "search", "q": query, "page": page])
        case .categories:
            request
        }
    }
}

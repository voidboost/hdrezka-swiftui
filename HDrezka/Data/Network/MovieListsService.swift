import Alamofire
import Foundation

enum MovieListsService {
    case getMovieList1(page: Int, filter: String, genre: Int)
    case getMovieList2(type: String, listType: String, genre: String?, year: String?, page: Int)
    case getMovieList3(type: String, genre: String?, page: Int, filter: String)
    case getMovieList4(type: String, category: String, page: Int, genre: Int, filter: String)
    case getNewestMovies(page: Int, filter: String, genre: Int)
    case getHotMovies(genre: Int)
}

extension MovieListsService: Endpoint {
    var path: String {
        switch self {
        case let .getMovieList1(page, _, _):
            "".page(page)
        case let .getMovieList2(type, listType, genre, year, page):
            ([type, listType, genre, year].compactMap(\.self).joined(separator: "/") + "/").page(page)
        case let .getMovieList3(type, genre, page, _):
            ([type, genre].compactMap(\.self).joined(separator: "/") + "/").page(page)
        case let .getMovieList4(type, category, page, _, _):
            "\(type)/\(category)/".page(page)
        case let .getNewestMovies(page, _, _):
            "new/".page(page)
        case .getHotMovies:
            "engine/ajax/get_newest_slider_content.php"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getHotMovies:
            .post
        default:
            .get
        }
    }

    func encode(_ request: URLRequest) throws -> URLRequest {
        switch self {
        case let .getMovieList1(_, filter, genre), let .getMovieList4(_, _, _, genre, filter), let .getNewestMovies(_, filter, genre):
            var params: Parameters = ["filter": filter]
            if genre != 0 {
                params["genre"] = genre
            }

            return try request.query(params)
        case let .getMovieList3(_, _, _, filter):
            return try request.query(["filter": filter])
        case let .getHotMovies(genre):
            return try request.body(["id": genre])
        case .getMovieList2:
            return request
        }
    }
}

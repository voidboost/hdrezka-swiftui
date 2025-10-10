import Alamofire
import Defaults
import Foundation

enum MovieListsService {
    case getMovieList1(page: Int, filter: String, genre: Int)
    case getMovieList2(type: String, listType: String, genre: String?, year: String?, page: Int)
    case getMovieList3(type: String, genre: String?, page: Int, filter: String)
    case getMovieList4(type: String, category: String, page: Int, genre: Int, filter: String)
    case getNewestMovies(page: Int, filter: String, genre: Int)
    case getHotMovies(genre: Int)
}

extension MovieListsService: URLRequestConvertible {
    var baseURL: URL { Defaults[.mirror] }

    var path: String {
        switch self {
        case let .getMovieList1(page, _, _):
            "".page(page)
        case let .getMovieList2(type, listType, genre, year, page):
            if let genre, let year {
                "\(type)/\(listType)/\(genre)/\(year)/".page(page)
            } else if let genre {
                "\(type)/\(listType)/\(genre)/".page(page)
            } else if let year {
                "\(type)/\(listType)/\(year)/".page(page)
            } else {
                "\(type)/\(listType)/".page(page)
            }
        case let .getMovieList3(type, genre, page, _):
            if let genre {
                "\(type)/\(genre)/".page(page)
            } else {
                "\(type)/".page(page)
            }
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

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appending(path: path, directoryHint: .notDirectory)

        var request = URLRequest(url: url)
        request.method = method
        request.headers = Const.headers

        switch self {
        case let .getMovieList1(_, filter, genre):
            var params: [String: Any] = [:]
            params["filter"] = filter
            params["genre"] = genre != 0 ? genre : nil

            return try URLEncoding.queryString.encode(request, with: params)
        case let .getMovieList3(_, _, _, filter):
            return try URLEncoding.queryString.encode(request, with: ["filter": filter])
        case let .getMovieList4(_, _, _, genre, filter):
            var params: [String: Any] = [:]
            params["filter"] = filter
            params["genre"] = genre != 0 ? genre : nil

            return try URLEncoding.queryString.encode(request, with: params)
        case let .getNewestMovies(_, filter, genre):
            var params: [String: Any] = [:]
            params["filter"] = filter
            params["genre"] = genre != 0 ? genre : nil

            return try URLEncoding.queryString.encode(request, with: params)
        case let .getHotMovies(genre):
            return try URLEncoding.httpBody.encode(request, with: ["id": genre])
        default:
            return request
        }
    }
}

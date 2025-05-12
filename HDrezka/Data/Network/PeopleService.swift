import Alamofire
import Defaults
import Foundation

enum PeopleService {
    case getPersonDetails(id: String)
}

extension PeopleService: URLRequestConvertible {
    var baseURL: URL { URL(string: Defaults[.mirror]) ?? URL(string: Const.mirror)! }

    var path: String {
        switch self {
        case let .getPersonDetails(id):
            "person/\(id)"
        }
    }

    var method: HTTPMethod { .get }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appending(path: path, directoryHint: .notDirectory)

        var request = URLRequest(url: url)
        request.method = method
        request.headers = Const.headers

        return request
    }
}

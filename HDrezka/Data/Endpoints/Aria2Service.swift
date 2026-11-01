import Alamofire
import Foundation

struct Aria2Service {
    let body: Data
}

extension Aria2Service: Endpoint {
    var baseURL: URL {
        Const.rpc
    }

    var path: String {
        "jsonrpc"
    }

    var method: HTTPMethod {
        .post
    }

    var headers: HTTPHeaders {
        [.contentType("application/json-rpc")]
    }

    func encode(_ request: URLRequest) throws -> URLRequest {
        var request = request
        request.httpBody = body

        return request
    }
}

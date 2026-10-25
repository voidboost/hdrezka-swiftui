import Alamofire
import Foundation

enum Aria2Service<E: Encodable & Sendable> {
    case call(data: E)
    case multicall(data: [E])
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
        switch self {
        case let .call(data):
            try JSONParameterEncoder.default.encode(data, into: request)
        case let .multicall(data):
            try JSONParameterEncoder.default.encode(data, into: request)
        }
    }
}

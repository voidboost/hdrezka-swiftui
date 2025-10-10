import Alamofire
import Defaults
import Foundation

enum Aria2Service<E: Encodable & Sendable> {
    case call(data: E)
    case multicall(data: [E])
}

extension Aria2Service: URLRequestConvertible {
    var baseURL: URL { Const.rpc }

    var path: String { "jsonrpc" }

    var method: HTTPMethod { .post }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appending(path: path, directoryHint: .notDirectory)

        var request = URLRequest(url: url)
        request.method = method
        request.headers = HTTPHeaders([.contentType("application/json-rpc")])

        switch self {
        case let .call(data):
            return try JSONParameterEncoder.default.encode(data, into: request)
        case let .multicall(data):
            return try JSONParameterEncoder.default.encode(data, into: request)
        }
    }
}

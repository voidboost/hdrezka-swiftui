import Alamofire
import Defaults
import Foundation

protocol Endpoint: URLRequestConvertible {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders { get }

    func encode(_ request: URLRequest) throws -> URLRequest
}

extension Endpoint {
    var baseURL: URL {
        Defaults[.mirror]
    }

    var method: HTTPMethod {
        .get
    }

    var headers: HTTPHeaders {
        Const.headers
    }

    func encode(_ request: URLRequest) throws -> URLRequest {
        request
    }

    func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path, directoryHint: .notDirectory))
        request.method = method
        request.headers = headers

        return try encode(request)
    }
}

extension URLRequest {
    func query(_ parameters: Parameters) throws -> URLRequest {
        try URLEncoding.queryString.encode(self, with: parameters)
    }

    func body(_ parameters: Parameters) throws -> URLRequest {
        try URLEncoding.httpBody.encode(self, with: parameters)
    }

    func timestamped() throws -> URLRequest {
        try query(["t": Int.timestamp])
    }
}

extension Int {
    static var timestamp: Int {
        Int(Date().timeIntervalSince1970 * 1000)
    }
}

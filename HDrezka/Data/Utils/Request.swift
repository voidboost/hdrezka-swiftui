import Alamofire
import Combine
import Foundation

let parsingQueue = DispatchQueue(label: "io.silentsea.hdrezka.parsingQueue", qos: .userInitiated, attributes: .concurrent)

struct JSONObject {
    let raw: [String: Any]
    let function: String

    subscript<V>(_ key: String) -> V? {
        raw[key] as? V
    }

    func require<V>(_ key: String) throws -> V {
        guard let value = raw[key] as? V else {
            throw HDrezkaError.parseJson(key, function)
        }

        return value
    }
}

extension Session {
    func string<T>(_ convertible: URLRequestConvertible, parse: @escaping (String) throws -> T) -> AnyPublisher<T, Error> {
        request(convertible)
            .validate(statusCode: 200 ..< 400)
            .publishString(queue: parsingQueue)
            .value()
            .tryMap(parse)
            .receive(on: DispatchQueue.main)
            .handleError()
    }

    func json<T>(_ convertible: URLRequestConvertible, function: String, parse: @escaping (JSONObject) throws -> T) -> AnyPublisher<T, Error> {
        request(convertible)
            .validate(statusCode: 200 ..< 400)
            .publishData(queue: parsingQueue)
            .value()
            .tryMap { data in
                guard let raw = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                    throw HDrezkaError.parseJson("json", function)
                }

                return try parse(JSONObject(raw: raw, function: function))
            }
            .receive(on: DispatchQueue.main)
            .handleError()
    }

    func success(_ convertible: URLRequestConvertible, function: String) -> AnyPublisher<Bool, Error> {
        json(convertible, function: function) { try $0.require("success") }
    }

    func perform(_ convertible: URLRequestConvertible) -> AnyPublisher<Bool, Error> {
        request(convertible)
            .validate(statusCode: 200 ..< 400)
            .publishUnserialized(queue: parsingQueue)
            .value()
            .map { _ in true }
            .receive(on: DispatchQueue.main)
            .handleError()
    }
}

func invalidInput<T>(
    functionName: String = #function,
    lineNumber: Int = #line,
    columnNumber: Int = #column
) -> AnyPublisher<T, Error> {
    Fail(error: HDrezkaError.null(functionName, lineNumber, columnNumber))
        .handleError()
}

extension String {
    var pathParts: [String] {
        components(separatedBy: "/").filter { !$0.isEmpty }
    }
}

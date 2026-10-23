import Alamofire
import Foundation

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
    @concurrent
    func string<T>(_ convertible: URLRequestConvertible, parse: (String) throws -> T) async throws -> T {
        try await handlingErrors {
            let string = try await request(convertible)
                .validate(statusCode: 200 ..< 400)
                .serializingString()
                .value

            return try parse(string)
        }
    }

    @concurrent
    func json<T>(_ convertible: URLRequestConvertible, function: String, parse: (JSONObject) throws -> T) async throws -> T {
        try await handlingErrors {
            let data = try await request(convertible)
                .validate(statusCode: 200 ..< 400)
                .serializingData()
                .value

            guard let raw = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
                throw HDrezkaError.parseJson("json", function)
            }

            return try parse(JSONObject(raw: raw, function: function))
        }
    }

    func success(_ convertible: URLRequestConvertible, function: String) async throws -> Bool {
        try await json(convertible, function: function) { try $0.require("success") }
    }

    @concurrent
    func perform(_ convertible: URLRequestConvertible) async throws -> Bool {
        try await handlingErrors {
            _ = try await request(convertible)
                .validate(statusCode: 200 ..< 400)
                .serializingData(emptyResponseCodes: Set(200 ..< 400))
                .value

            return true
        }
    }
}

func handlingErrors<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch {
        throw handleError(error)
    }
}

func invalidInput(
    functionName: String = #function,
    lineNumber: Int = #line,
    columnNumber: Int = #column
) -> Error {
    handleError(HDrezkaError.null(functionName, lineNumber, columnNumber))
}

extension String {
    var pathParts: [String] {
        components(separatedBy: "/").filter { !$0.isEmpty }
    }
}

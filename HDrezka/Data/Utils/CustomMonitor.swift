import Alamofire
import Defaults
import FirebaseCrashlytics
import Foundation

final class CustomMonitor: EventMonitor {
    func request<Value>(_: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        #if DEBUG
            print(response.customDebugDescription)
        #else
            Crashlytics.crashlytics().log(response.customDebugDescription)
        #endif

        check()
    }

    private func check() {
        let isLoggedIn = HTTPCookieStorage.shared.cookies(for: URL(string: Defaults[.mirror]) ?? URL(string: Const.mirror)!)?.first { $0.name == "dle_password" }?.value.isNotEqualAndNotEmpty("deleted") ?? false

        Defaults[.isLoggedIn] = isLoggedIn

        if !isLoggedIn {
            Defaults[.isUserPremium] = nil
        }

        Defaults[.allowedComments] = HTTPCookieStorage.shared.cookies(for: URL(string: Defaults[.mirror]) ?? URL(string: Const.mirror)!)?.first { $0.name == "allowed_comments" }?.value.isEqual("1") ?? false
    }
}

extension DataResponse {
    var customDebugDescription: String {
        guard let urlRequest = request else { return "[Request]: None\n[Result]: \(result)" }

        let requestDescription = DebugDescription.description(of: urlRequest)

        let responseDescription = response.map { response in
            let responseBodyDescription = DebugDescription.description(for: data, headers: response.headers)

            return """
            \(DebugDescription.description(of: response))
                \(responseBodyDescription.indentingNewlines())
            """
        } ?? "[Response]: None"

        let networkDuration = metrics.map { "\($0.taskInterval.duration.formatted(.number.grouping(.never).precision(.fractionLength(10))))s" } ?? "None"

        if case let .failure(error) = result {
            return """
            \(requestDescription)
            \(responseDescription)
            [Network Duration]: \(networkDuration)
            [Serialization Duration]: \(serializationDuration.formatted(.number.grouping(.never).precision(.fractionLength(10))))s
            [Error]: \(error.localizedDescription)
            """
        } else {
            return """
            \(requestDescription)
            \(responseDescription)
            [Network Duration]: \(networkDuration)
            [Serialization Duration]: \(serializationDuration.formatted(.number.grouping(.never).precision(.fractionLength(10))))s
            """
        }
    }
}

private enum DebugDescription {
    static func description(of request: URLRequest) -> String {
        let requestSummary = "\(request.httpMethod!) \(request)"
        let requestHeadersDescription = DebugDescription.description(for: request.headers)
        let requestBodyDescription = DebugDescription.description(for: request.httpBody, headers: request.headers)

        return """
        [Request]: \(requestSummary)
            \(requestHeadersDescription.indentingNewlines())
            \(requestBodyDescription.indentingNewlines())
        """
    }

    static func description(of response: HTTPURLResponse) -> String {
        """
        [Response]:
            [Status Code]: \(response.statusCode)
            \(DebugDescription.description(for: response.headers).indentingNewlines())
        """
    }

    static func description(for headers: HTTPHeaders) -> String {
        guard !headers.isEmpty else { return "[Headers]: None" }

        #if !DEBUG
            var headers = headers
            headers.remove(name: "Cookie")
            headers.remove(name: "Set-Cookie")
        #endif

        let headerDescription = "\(headers.sorted())".indentingNewlines()

        return """
        [Headers]:
            \(headerDescription)
        """
    }

    static func description(for data: Data?,
                            headers: HTTPHeaders,
                            allowingPrintableTypes printableTypes: [String] = ["json", "xml", "text", "x-www-form-urlencoded"]) -> String
    {
        guard let data, !data.isEmpty else { return "[Body]: None" }

        var maximumLength: Int {
            #if DEBUG
                .max
            #else
                10000
            #endif
        }

        guard data.count <= maximumLength,
              printableTypes.compactMap({ headers["Content-Type"]?.contains($0) }).contains(true)
        else {
            return "[Body]: \(data.count) bytes"
        }

        return """
        [Body]:
            \(String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .indentingNewlines())
        """
    }
}

private extension String {
    func indentingNewlines(by spaceCount: Int = 4) -> String {
        let spaces = String(repeating: " ", count: spaceCount)
        return replacingOccurrences(of: "\n", with: "\n\(spaces)")
    }
}

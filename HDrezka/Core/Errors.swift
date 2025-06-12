import Foundation

enum HDrezkaError: Error {
    case mirrorBanned(URL)
    case loginRequired(URL)
    case skipLink(URL)
    case parseJson(String, String)
    case null(String, Int, Int)
    case swiftsoup(String, String)
    case unknown
}

extension HDrezkaError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .mirrorBanned(mirror):
            String(localized: "key.errors.mirror-\(mirror.host() ?? "")")
        case let .loginRequired(mirror):
            String(localized: "key.errors.login-\(mirror.host() ?? "")")
        case let .skipLink(link):
            String(localized: "key.errors.link-\(link.absoluteString)")
        case let .parseJson(param, function):
            String(localized: "key.errors.parsing-\(param)-\(function)")
        case let .null(functionName, lineNumber, columnNumber):
            String(localized: "key.errors.null-\(functionName)-\(lineNumber)-\(columnNumber)")
        case let .swiftsoup(type, message):
            String(localized: "key.errors.swiftsoup-\(type)-\(message)")
        case .unknown:
            String(localized: "key.errors.unknown")
        }
    }
}

extension HDrezkaError: CustomNSError {
    var errorUserInfo: [String: Any] {
        if let errorDescription {
            [NSLocalizedDescriptionKey: errorDescription]
        } else {
            [:]
        }
    }
}

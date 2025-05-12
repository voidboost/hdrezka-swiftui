import Foundation

enum HDrezkaError: Error {
    case mirrorBanned(String)
    case loginRequired(String)
    case skipLink(String)
    case parseJson(String, String)
    case null(String, Int, Int)
    case swiftsoup(String, String)
}

extension HDrezkaError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .mirrorBanned(let mirror):
            String(localized: "key.errors.mirror-\(mirror)")
        case .loginRequired(let mirror):
            String(localized: "key.errors.login-\(mirror)")
        case .skipLink(let link):
            String(localized: "key.errors.link-\(link)")
        case .parseJson(let param, let function):
            String(localized: "key.errors.parsing-\(param)-\(function)")
        case .null(let functionName, let lineNumber, let columnNumber):
            String(localized: "key.errors.null-\(functionName)-\(lineNumber)-\(columnNumber)")
        case .swiftsoup(let type, let message):
            String(localized: "key.errors.swiftsoup-\(type)-\(message)")
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

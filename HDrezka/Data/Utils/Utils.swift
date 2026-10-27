import Alamofire
import AVFoundation
import Defaults
import Dependencies
import FirebaseCrashlytics
import Foundation
import SwiftSoup

extension SwiftSoup.Document {
    func checkPage() throws {
        let body = try body().orThrow()

        guard try body.select("#check-form").isEmpty() else {
            throw HDrezkaError.loginRequired(Defaults[.mirror])
        }

        guard try !body.select("#wrapper").isEmpty() else {
            throw HDrezkaError.mirrorBanned(Defaults[.mirror])
        }
    }

    func getPremiumDays() throws -> Int? {
        try Int(select(".b-tophead-premuser b").text().trimmingCharacters(in: .decimalDigits.inverted))
    }
}

extension String {
    var id: String? {
        URL(string: self)?.id
    }

    var cleanPath: String? {
        URL(string: self)?.cleanPath
    }

    var isNumber: Bool {
        CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }

    private static let shortNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        formatter.allowsFloats = true
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static let shortNumberAbbreviations: [(threshold: Double, suffix: String)] = [
        (1_000_000_000, "B"),
        (1_000_000, "M"),
        (1000, "K"),
    ]

    var shortNumber: String {
        guard let number = Int(String(unicodeScalars.filter(CharacterSet.decimalDigits.contains))) else {
            return "0"
        }

        let value = Double(number)
        let (divisor, suffix) = Self.shortNumberAbbreviations.first { value >= $0.threshold } ?? (1, "")

        return (Self.shortNumberFormatter.string(from: NSNumber(value: value / divisor)) ?? "0") + suffix
    }

    func page(_ page: Int) -> String {
        if page > 1 {
            appending("page/\(page)/")
        } else {
            self
        }
    }

    func substringBefore(_ separator: String, includeSeparator: Bool = false) -> String {
        if let range = range(of: separator) {
            if includeSeparator {
                String(self[..<range.upperBound])
            } else {
                String(self[..<range.lowerBound])
            }
        } else {
            self
        }
    }

    func substringBeforeLast(_ separator: String, includeSeparator: Bool = false) -> String {
        if let range = range(of: separator, options: .backwards) {
            if includeSeparator {
                String(self[..<range.upperBound])
            } else {
                String(self[..<range.lowerBound])
            }
        } else {
            self
        }
    }

    func substringAfter(_ separator: String, includeSeparator: Bool = false) -> String {
        if let range = range(of: separator) {
            if includeSeparator {
                String(self[range.lowerBound...])
            } else {
                String(self[range.upperBound...])
            }
        } else {
            self
        }
    }

    func substringAfterLast(_ separator: String, includeSeparator: Bool = false) -> String {
        if let range = range(of: separator, options: .backwards) {
            if includeSeparator {
                String(self[range.lowerBound...])
            } else {
                String(self[range.upperBound...])
            }
        } else {
            self
        }
    }
}

extension Optional {
    func orThrow(
        functionName: String = #function,
        lineNumber: Int = #line,
        columnNumber: Int = #column
    ) throws -> Wrapped {
        guard let self else {
            let error = HDrezkaError.null(functionName, lineNumber, columnNumber)
            Crashlytics.crashlytics().record(error: error)
            throw error
        }

        return self
    }
}

func handleError(_ error: Error) -> Error {
    @Dependency(\.sessionEvents) var sessionEvents

    if error is CancellationError || error.asAFError?.isExplicitlyCancelledError == true {
        return error
    } else if let avError = error as? AVError {
        recordToCrashlytics(avError)

        return avError
    } else if let afError = error.asAFError {
        if afError.responseCode == 403 {
            sessionEvents.send(.loginRequired)

            return HDrezkaError.loginRequired(Defaults[.mirror])
        }

        if afError.responseCode == nil, !afError.isSessionTaskError {
            recordToCrashlytics(afError)
        }

        return afError
    } else if let hdrezkaError = error as? HDrezkaError {
        switch hdrezkaError {
        case .loginRequired:
            sessionEvents.send(.loginRequired)
        case .mirrorBanned, .site:
            break
        default:
            recordToCrashlytics(hdrezkaError)
        }

        return hdrezkaError
    } else if let exception = error as? Exception, case let .Error(type, message) = exception {
        let hdrezkaError = HDrezkaError.swiftsoup("\(type)", message)

        recordToCrashlytics(hdrezkaError)

        return hdrezkaError
    }

    return error
}

private func recordToCrashlytics(_ error: Error) {
    Crashlytics.crashlytics().record(error: error)
}

@MainActor
enum LaunchErrors {
    private static var pending: [any Error]? = []

    static func record(_ error: any Error) {
        if pending != nil {
            pending?.append(error)
        } else {
            Crashlytics.crashlytics().record(error: error)
        }
    }

    static func flush() {
        pending?.forEach { Crashlytics.crashlytics().record(error: $0) }
        pending = nil
    }
}

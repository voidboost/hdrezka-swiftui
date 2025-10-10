import Alamofire
import AVFoundation
import Combine
import Defaults
import FirebaseCrashlytics
import Foundation
import SwiftSoup
import SwiftUI

extension Document {
    func checker() throws -> Document {
        let body = try body().orThrow()

        guard try body.select("#check-form").isEmpty() else {
            AppState.shared.isSignInPresented = true

            throw HDrezkaError.loginRequired(Defaults[.mirror])
        }

        guard try !body.select("#wrapper").isEmpty() else {
            throw HDrezkaError.mirrorBanned(Defaults[.mirror])
        }

        Defaults[.isUserPremium] = try Int(body.select(".b-tophead-premuser").select("b").text().trimmingCharacters(in: .decimalDigits.inverted))

        return self
    }
}

extension String {
    var id: String? {
        let string = if hasPrefix("/") {
            String(dropFirst())
        } else {
            self
        }

        let parts = string.components(separatedBy: "/").filter { !$0.isEmpty }

        if parts.count == 3, let id = parts[2].components(separatedBy: "-").filter({ !$0.isEmpty }).first, !id.isEmpty, id.isNumber, parts[2].hasSuffix(".html") {
            return id
        }

        return nil
    }

    var shortNumber: String {
        if let number = Int(String(unicodeScalars.filter(CharacterSet.decimalDigits.contains))) {
            let numFormatter = NumberFormatter()

            struct Abbrevation {
                let threshold: Double
                let divisor: Double
                let suffix: String
            }

            let abbreviations: [Abbrevation] = [.init(threshold: 0, divisor: 1, suffix: ""),
                                                .init(threshold: 1000.0, divisor: 1000.0, suffix: "K"),
                                                .init(threshold: 1_000_000.0, divisor: 1_000_000.0, suffix: "M"),
                                                .init(threshold: 1_000_000_000.0, divisor: 1_000_000_000.0, suffix: "B")]

            let startValue = Double(abs(number))
            var abbreviation: Abbrevation {
                var prevAbbreviation: Abbrevation = .init(threshold: 0, divisor: 1, suffix: "")
                for tmpAbbreviation in abbreviations {
                    if startValue < tmpAbbreviation.threshold {
                        break
                    }
                    prevAbbreviation = tmpAbbreviation
                }
                return prevAbbreviation
            }

            let value = Double(number) / abbreviation.divisor
            numFormatter.positiveSuffix = abbreviation.suffix
            numFormatter.negativeSuffix = abbreviation.suffix
            numFormatter.decimalSeparator = "."
            numFormatter.allowsFloats = true
            numFormatter.minimumIntegerDigits = 1
            numFormatter.minimumFractionDigits = 0
            numFormatter.maximumFractionDigits = 1

            return numFormatter.string(from: NSNumber(value: value)) ?? "0"
        } else {
            return "0"
        }
    }

    var isNumber: Bool {
        CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }

    func removeMirror(_ scheme: String = "http") -> String {
        if hasPrefix(scheme) {
            components(separatedBy: "/").filter { !$0.isEmpty }.dropFirst(2).joined(separator: "/")
        } else if hasPrefix("/") {
            String(dropFirst())
        } else {
            self
        }
    }

    func isNotEqualAndNotEmpty(_ str: String) -> Bool {
        self != str && !isEmpty
    }

    func isEqual(_ str: String) -> Bool {
        self == str
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
        columnNumber: Int = #column,
    ) throws -> Wrapped {
        guard let self else {
            let error = HDrezkaError.null(functionName, lineNumber, columnNumber)
            Crashlytics.crashlytics().record(error: error)
            throw error
        }

        return self
    }
}

class AttributedTextStyle {
    private(set) var attributes: [NSAttributedString.Key: Any] = [:]

    func font(
        bold: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        strikethrough: Bool = false,
        link: String? = nil,
    ) {
        var font = NSFont.systemFont(ofSize: 13)
        let fontManager = NSFontManager.shared

        if bold {
            font = fontManager.convert(font, toHaveTrait: .boldFontMask)
        }

        if italic {
            font = fontManager.convert(font, toHaveTrait: .italicFontMask)
        }

        self.font(font, underline, strikethrough, link)
    }

    func font(_ font: NSFont, _ underline: Bool, _ strikethrough: Bool, _ link: String?) {
        attributes[.font] = font
        attributes[.foregroundColor] = NSColor.labelColor

        if underline {
            attributes[.underlineStyle] = 1
        }

        if strikethrough {
            attributes[.strikethroughStyle] = 1
        }

        if let link {
            attributes[.link] = link
            attributes[.foregroundColor] = NSColor(Color.accentColor)
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping

        attributes[.paragraphStyle] = paragraphStyle
    }
}

extension NSMutableAttributedString {
    func append(string: String, _ styleConfigurationBlock: (AttributedTextStyle) -> Void) {
        let style = AttributedTextStyle()
        styleConfigurationBlock(style)
        append(NSAttributedString(string: string, attributes: style.attributes))
    }
}

extension Publisher where Failure == Error {
    func handleError() -> AnyPublisher<Output, Failure> {
        mapError(handleError)
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output == Error, Failure == Never {
    func handleError() -> AnyPublisher<Output, Failure> {
        map(handleError)
            .eraseToAnyPublisher()
    }
}

private extension Publisher {
    func handleError(error: Error) -> Error {
        if let avError = error as? AVError {
            recordToCrashlytics(avError)

            return avError
        } else if let afError = error.asAFError {
            if afError.responseCode != nil || afError.isSessionTaskError {
                return afError
            }

            recordToCrashlytics(afError)

            return afError
        } else if let hdrezkaError = error as? HDrezkaError {
            if case .mirrorBanned = hdrezkaError {
                return hdrezkaError
            } else if case .loginRequired = hdrezkaError {
                return hdrezkaError
            }

            recordToCrashlytics(hdrezkaError)

            return hdrezkaError
        } else if let exception = error as? Exception, case let .Error(type, message) = exception {
            let hdrezkaError = HDrezkaError.swiftsoup("\(type)", message)

            recordToCrashlytics(hdrezkaError)

            return hdrezkaError
        }

        return error
    }

    func recordToCrashlytics(_ error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}

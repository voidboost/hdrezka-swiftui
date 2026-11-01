import SwiftUI

extension String {
    var firstLetterUppercased: String {
        guard let first, first.isLowercase else { return self }
        return first.uppercased() + dropFirst()
    }

    var isValidHost: Bool {
        guard !isEmpty, count <= 253 else { return false }

        let lowercased = lowercased()

        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-.")
        guard lowercased.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }

        let labels = lowercased.components(separatedBy: ".")

        guard labels.count >= 2,
              labels.allSatisfy({ !$0.isEmpty && $0.count <= 63 && !$0.hasPrefix("-") && !$0.hasSuffix("-") })
        else {
            return false
        }

        guard let tld = labels.last,
              tld.count >= 2,
              tld.allSatisfy(\.isLetter)
        else {
            return false
        }

        return true
    }
}

extension LocalizedStringKey {
    func toString() -> String? {
        guard let attributeLabelAndValue = Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as? String else { return nil }

        return String.localizedStringWithFormat(NSLocalizedString(attributeLabelAndValue, comment: ""))
    }
}

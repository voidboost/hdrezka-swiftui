import SwiftUI

extension String {
    func firstLetterUppercased() -> String {
        guard let first, first.isLowercase else { return self }
        return first.uppercased() + dropFirst()
    }

    func removeLastCharacterIf(character: Character) -> String {
        guard let last, last == character else { return self }

        return String(dropLast())
    }
}

extension LocalizedStringKey {
    func toString() -> String? {
        guard let attributeLabelAndValue = Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as? String else { return nil }

        return String.localizedStringWithFormat(NSLocalizedString(attributeLabelAndValue, comment: ""))
    }
}

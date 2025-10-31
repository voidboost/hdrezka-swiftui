import SwiftUI

extension String {
    func firstLetterUppercased() -> String {
        guard let first, first.isLowercase else { return self }
        return first.uppercased() + dropFirst()
    }
}

extension LocalizedStringKey {
    func toString() -> String? {
        guard let attributeLabelAndValue = Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as? String else { return nil }

        return String.localizedStringWithFormat(NSLocalizedString(attributeLabelAndValue, comment: ""))
    }
}

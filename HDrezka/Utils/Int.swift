import Foundation

extension Int {
    var ordinal: String {
        NumberFormatter.localizedString(from: NSNumber(value: self), number: .ordinal)
    }
}

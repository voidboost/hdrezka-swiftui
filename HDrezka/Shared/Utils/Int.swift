import Foundation

extension Int {
    func toNumeral() -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: self))
    }
}

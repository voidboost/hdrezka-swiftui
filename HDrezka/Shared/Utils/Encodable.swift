import Foundation

extension Encodable {
    var dictionary: [String: Any] {
        let encoder = JSONEncoder()
        return (try? JSONSerialization.jsonObject(with: encoder.encode(self), options: []) as? [String: Any]) ?? [:]
    }
}

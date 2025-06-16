import Combine
import Foundation

extension Set where Element == AnyCancellable {
    mutating func flush() {
        forEach { $0.cancel() }
        removeAll()
    }
}

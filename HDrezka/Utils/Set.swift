import Combine
import Foundation

extension Set<AnyCancellable> {
    mutating func flush() {
        forEach { $0.cancel() }
        removeAll()
    }
}

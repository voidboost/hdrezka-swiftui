import Foundation

protocol Named: Identifiable, Hashable {
    var name: String { get }
}

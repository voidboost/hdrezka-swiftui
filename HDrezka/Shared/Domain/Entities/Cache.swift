import Defaults
import SwiftUI

enum Cache: Int, CaseIterable, Identifiable, Defaults.Serializable {
    case off = 0
    case memory
    case disk
    case all

    var id: Self { self }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .off:
            "key.off"
        case .memory:
            "key.cache.memory"
        case .disk:
            "key.cache.disk"
        case .all:
            "key.cache.all"
        }
    }
}

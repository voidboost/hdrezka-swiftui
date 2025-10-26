import Defaults
import SwiftUI

enum DefaultQuality: String, CaseIterable, Identifiable, Defaults.Serializable {
    case ask
    case highest
    case p360 = "360p"
    case p480 = "480p"
    case p720 = "720p"
    case p1080 = "1080p"
    case p1080u = "1080p Ultra"
    case k2 = "2K"
    case k4 = "4K"

    var id: Self { self }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .ask:
            "key.ask"
        case .highest:
            "key.highest"
        case .p360:
            "key.360p"
        case .p480:
            "key.480p"
        case .p720:
            "key.720p"
        case .p1080:
            "key.1080p"
        case .p1080u:
            "key.1080pu"
        case .k2:
            "key.2k"
        case .k4:
            "key.4k"
        }
    }
}

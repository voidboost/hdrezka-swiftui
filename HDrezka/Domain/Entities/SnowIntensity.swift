import Defaults
import SwiftUI

enum SnowIntensity: Int, CaseIterable, Identifiable, Defaults.Serializable {
    case light = 0
    case steady
    case heavy
    case variable

    var id: Self {
        self
    }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .light:
            "key.snow.light"
        case .steady:
            "key.snow.steady"
        case .heavy:
            "key.snow.heavy"
        case .variable:
            "key.snow.variable"
        }
    }
}

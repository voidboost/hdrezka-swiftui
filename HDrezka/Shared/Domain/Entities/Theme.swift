import Defaults
import SwiftUI

enum Theme: Int, CaseIterable, Identifiable, Defaults.Serializable {
    case system = 0
    case light
    case dark

    var id: Self { self }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .system:
            "key.theme.system"
        case .light:
            "key.theme.light"
        case .dark:
            "key.theme.dark"
        }
    }

    var scheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

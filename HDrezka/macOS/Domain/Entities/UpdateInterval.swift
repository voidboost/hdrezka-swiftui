import SwiftUI

enum UpdateInterval: Double, CaseIterable, Identifiable {
    case hourly = 3600
    case daily = 86400
    case weekly = 604_800
    case monthly = 2_629_800

    var id: Self { self }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .hourly:
            "key.hourly"
        case .daily:
            "key.daily"
        case .weekly:
            "key.weekly"
        case .monthly:
            "key.monthly"
        }
    }
}

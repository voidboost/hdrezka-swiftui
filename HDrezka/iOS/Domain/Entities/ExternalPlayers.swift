import SwiftUI

enum ExternalPlayers: Int, CaseIterable, Identifiable {
    case infuse = 0

    var id: Self { self }

    var url: URL {
        switch self {
        case .infuse:
            URL(string: "infuse://x-callback-url/play")!
        }
    }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .infuse:
            "key.open.infuse"
        }
    }
}

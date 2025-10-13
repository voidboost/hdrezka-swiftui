import SwiftUI

enum ExternalPlayers: Int, CaseIterable, Identifiable {
    case iina = 0
    case infuse
    case mpv
    case vlc

    var id: Self { self }

    var url: URL {
        switch self {
        case .iina:
            URL(string: "iina://open")!
        case .infuse:
            URL(string: "infuse://x-callback-url/play")!
        case .mpv:
            URL(string: "mpv://temp")!
        case .vlc:
            URL(string: "vlc://temp")!
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .iina:
            "com.colliderli.iina"
        case .infuse:
            "com.firecore.infuse"
        case .mpv:
            "io.mpv"
        case .vlc:
            "org.videolan.vlc"
        }
    }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .iina:
            "key.open.iina"
        case .infuse:
            "key.open.infuse"
        case .mpv:
            "key.open.mpv"
        case .vlc:
            "key.open.vlc"
        }
    }
}

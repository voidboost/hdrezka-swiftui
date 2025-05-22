import Defaults
import Foundation

extension Defaults.Keys {
    static let mirror = Key<URL>("mirror", default: Const.mirror)
    static let lastHdrezkaAppVersion = Key<String>("last_hdrezka_app_version", default: Const.lastHdrezkaAppVersion)
    static let isUserPremium = Key<Int?>("is_user_premium", default: nil)
    static let isLoggedIn = Key<Bool>("is_logged_in", default: false)
    static let allowedComments = Key<Bool>("allowed_comments", default: false)
    static let defaultQuality = Key<DefaultQuality>("default_quality", default: .ask)

    static let navigationAnimation = Key<Bool>("navigation_animation", default: false)
    static let playerFullscreen = Key<Bool>("player_fullscreen", default: false)
    static let hideMainWindow = Key<Bool>("hide_main_window", default: false)
    static let spatialAudio = Key<SpatialAudio>("spatial_audio", default: .off)

    static let useHeaders = Key<Bool>("use_headers", default: true)
}

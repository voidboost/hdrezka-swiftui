import Defaults
import SwiftUI

extension Defaults.Keys {
    static let mirror = Key<URL>("mirror", default: Const.mirror)
    static let theme = Key<Theme>("theme", default: .system)
    static let defaultQuality = Key<DefaultQuality>("default_quality", default: .ask)

    static let spatialAudio = Key<SpatialAudio>("spatial_audio", default: .off)
    static let rate = Key<Float>("rate", default: 1.0)
    static let volume = Key<Float>("volume", default: 1.0)
    static let isMuted = Key<Bool>("is_muted", default: false)

    static let useHeaders = Key<Bool>("use_headers", default: true)
    static let lastHdrezkaAppVersion = Key<String>("last_hdrezka_app_version", default: Const.lastHdrezkaAppVersion)
    static let isUserPremium = Key<Int?>("is_user_premium", default: nil)
    static let isLoggedIn = Key<Bool>("is_logged_in", default: false)
    static let allowedComments = Key<Bool>("allowed_comments", default: false)
}

import AVFoundation
import Defaults
import SwiftUI

enum VideoGravity: Int, CaseIterable, Identifiable, Defaults.Serializable {
    case fit = 0
    case fill
    case stretch

    var id: Self {
        self
    }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .fit:
            "key.video_gravity.fit"
        case .fill:
            "key.video_gravity.fill"
        case .stretch:
            "key.video_gravity.stretch"
        }
    }

    var gravity: AVLayerVideoGravity {
        switch self {
        case .fit:
            .resizeAspect
        case .fill:
            .resizeAspectFill
        case .stretch:
            .resize
        }
    }
}

import AVFoundation
import Defaults
import SwiftUI

enum VideoGravity: Int, CaseIterable, Identifiable, Defaults.Serializable {
    case fit = 0
    case fill
    case stretch
    case ambient

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
        case .ambient:
            "key.video_gravity.ambient"
        }
    }

    var gravity: AVLayerVideoGravity {
        switch self {
        case .fit, .ambient:
            .resizeAspect
        case .fill:
            .resizeAspectFill
        case .stretch:
            .resize
        }
    }
}

import AVFoundation
import Defaults
import SwiftUI

enum SpatialAudio: Int, CaseIterable, Identifiable, Defaults.Serializable {
    case off = 0
    case monoAndStereo
    case multichannel
    case monoStereoAndMultichannel

    var id: Self { self }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .off:
            "key.off"
        case .monoAndStereo:
            "key.monoAndStereo"
        case .multichannel:
            "key.multichannel"
        case .monoStereoAndMultichannel:
            "key.monoStereoAndMultichannel"
        }
    }

    var format: AVAudioSpatializationFormats {
        switch self {
        case .off:
            .init(rawValue: 0)
        case .monoAndStereo:
            .monoAndStereo
        case .multichannel:
            .multichannel
        case .monoStereoAndMultichannel:
            .monoStereoAndMultichannel
        }
    }
}

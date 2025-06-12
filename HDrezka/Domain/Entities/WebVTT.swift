import Foundation

struct WebVTT {
    struct Cue {
        let timing: Timing
        let imageUrl: String?
        let frame: CGRect?
    }

    struct Timing {
        let start: Int
        let end: Int
    }

    let cues: [Cue]
}

extension WebVTT.Cue {
    var timeStart: TimeInterval {
        return TimeInterval(timing.start) / 1000
    }

    var timeEnd: TimeInterval {
        return TimeInterval(timing.end) / 1000
    }
}

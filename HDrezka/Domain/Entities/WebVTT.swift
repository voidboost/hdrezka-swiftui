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
        TimeInterval(timing.start) / 1000
    }

    var timeEnd: TimeInterval {
        TimeInterval(timing.end) / 1000
    }
}

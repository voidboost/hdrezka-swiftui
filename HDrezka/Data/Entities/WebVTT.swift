import Foundation

struct WebVTT {
    struct Cue {
        let timing: Timing
        let imageUrl: String?
        let frame: VttFrame?
    }

    struct Timing {
        let start: Int
        let end: Int
    }

    let cues: [Cue]

    init(cues: [Cue]) {
        self.cues = cues
    }
}

extension WebVTT.Cue {
    var timeStart: TimeInterval {
        return TimeInterval(timing.start) / 1000
    }

    var timeEnd: TimeInterval {
        return TimeInterval(timing.end) / 1000
    }
}

struct VttFrame: Codable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

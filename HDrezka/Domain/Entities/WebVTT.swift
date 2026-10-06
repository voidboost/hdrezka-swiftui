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

extension WebVTT {
    func cue(at time: TimeInterval) -> Cue? {
        var low = 0
        var high = cues.count

        while low < high {
            let mid = (low + high) / 2

            if cues[mid].timeEnd <= time {
                low = mid + 1
            } else {
                high = mid
            }
        }

        guard low < cues.count, cues[low].timeStart < time, time < cues[low].timeEnd else {
            return nil
        }

        return cues[low]
    }
}

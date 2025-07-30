import Alamofire
import Combine
import Foundation

struct Download: Hashable {
    let gid: String
    private(set) var status: StatusResult?
    let data: DownloadData
    let fileURL: URL

    init(gid: String, data: DownloadData, fileURL: URL) {
        self.gid = gid
        status = nil
        self.data = data
        self.fileURL = fileURL
    }
}

extension Download {
    mutating func updateStatus(_ status: StatusResult) {
        self.status = status
    }

    mutating func pause() {
        status?.pause()
    }

    mutating func unpause() {
        status?.unpause()
    }

    var progress: Progress {
        let progress = Progress()

        progress.kind = .file
        progress.fileOperationKind = .downloading
        progress.localizedDescription = data.name

        if let status {
            switch status.status {
            case .active:
                progress.totalUnitCount = status.totalLength
                progress.completedUnitCount = status.completedLength

                if status.downloadSpeed > 0 {
                    progress.throughput = status.downloadSpeed
                    progress.estimatedTimeRemaining = (Double(status.totalLength) - Double(status.completedLength)) / Double(status.downloadSpeed)
                }
            case .waiting:
                progress.totalUnitCount = status.totalLength
                progress.completedUnitCount = status.completedLength
            case .paused:
                progress.totalUnitCount = status.totalLength
                progress.completedUnitCount = status.completedLength
            case .error:
                break
            case .complete:
                break
            case .removed:
                break
            }
        }

        return progress
    }
}

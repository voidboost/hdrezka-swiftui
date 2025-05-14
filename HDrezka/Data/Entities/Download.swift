import Alamofire
import Foundation

struct Download: Identifiable, Hashable {
    let id: String
    private let request: DownloadRequest
    let progress: Progress

    init(id: String, request: DownloadRequest) {
        self.id = id
        self.request = request
        self.progress = self.request.downloadProgress
    }
}

extension Download {
    func cancel() {
        request.cancel()
    }
}

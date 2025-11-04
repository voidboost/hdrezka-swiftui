import Alamofire
import Combine
import Foundation

struct Download: Identifiable, Hashable {
    let id: String
    let data: DownloadData
    let progress: Progress
    private let cancellable: AnyCancellable

    init(id: String, data: DownloadData, request: DownloadRequest) {
        self.id = id
        self.data = data
        progress = request.downloadProgress
        cancellable = AnyCancellable { request.cancel() }
    }
}

extension Download {
    func cancel() {
        cancellable.cancel()
    }
}

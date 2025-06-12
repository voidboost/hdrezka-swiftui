import Alamofire
import Combine
import Foundation

struct Download: Identifiable, Hashable {
    let id: String
    let progress: Progress
    private let cancellable: AnyCancellable

    init(id: String, request: DownloadRequest) {
        self.id = id
        progress = request.downloadProgress
        cancellable = AnyCancellable { request.cancel() }
    }
}

extension Download {
    func cancel() {
        cancellable.cancel()
    }
}

import Combine
import Foundation

struct Download: Identifiable, Hashable {
    let id: String
    let name: String
    private let task: URLSessionDownloadTask
    let progress: Progress

    init(id: String, name: String, task: URLSessionDownloadTask) {
        self.id = id
        self.name = name
        self.task = task
        self.progress = task.progress
    }
}

extension Download {
    func cancel() {
        task.cancel()
    }
}

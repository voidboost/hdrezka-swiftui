import ComposableArchitecture
import Foundation

enum DownloadCommand: Sendable {
    case download(DownloadData)
    case remove(gid: String)
}

struct DownloadCommands: Sendable {
    var send: @Sendable (DownloadCommand) -> Void
    var commands: @Sendable () -> AsyncStream<DownloadCommand>
}

extension DownloadCommands: DependencyKey {
    static let liveValue: Self = {
        let (stream, continuation) = AsyncStream.makeStream(of: DownloadCommand.self)

        return Self(
            send: { continuation.yield($0) },
            commands: { stream }
        )
    }()
}

extension DependencyValues {
    var downloadCommands: DownloadCommands {
        get { self[DownloadCommands.self] }
        set { self[DownloadCommands.self] = newValue }
    }
}

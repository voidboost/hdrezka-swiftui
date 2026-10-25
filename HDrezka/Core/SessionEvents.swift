import ComposableArchitecture
import Foundation

enum SessionEvent: Equatable, Sendable {
    case loginRequired
}

struct SessionEvents: Sendable {
    var send: @Sendable (SessionEvent) -> Void
    var events: @Sendable () -> AsyncStream<SessionEvent>
}

extension SessionEvents: DependencyKey {
    static let liveValue: Self = {
        let (stream, continuation) = AsyncStream.makeStream(of: SessionEvent.self)

        return Self(
            send: { continuation.yield($0) },
            events: { stream }
        )
    }()
}

extension DependencyValues {
    var sessionEvents: SessionEvents {
        get { self[SessionEvents.self] }
        set { self[SessionEvents.self] = newValue }
    }
}

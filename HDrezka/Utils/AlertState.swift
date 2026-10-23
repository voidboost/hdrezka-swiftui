import ComposableArchitecture

extension AlertState {
    static func error(_ error: (any Error)? = nil, message: String? = nil) -> Self {
        Self(
            title: { TextState("key.ops") },
            actions: { ButtonState(role: .cancel) { TextState("key.ok") } },
            message: (message ?? error?.localizedDescription).map { message in { TextState(message) } }
        )
    }
}

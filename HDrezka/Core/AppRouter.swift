import ComposableArchitecture
import Foundation

enum AppRoute: Equatable, Sendable {
    case signIn
    case premium
    case commentsRules
}

/// App-wide presentation requests that can originate anywhere (data layer, player window, sheets).
/// `AppFeature` consumes `routes()` once for the lifetime of the app.
struct AppRouter: Sendable {
    var present: @Sendable (AppRoute) -> Void
    var routes: @Sendable () -> AsyncStream<AppRoute>
}

extension AppRouter: DependencyKey {
    static let liveValue: Self = {
        let (stream, continuation) = AsyncStream.makeStream(of: AppRoute.self)

        return Self(
            present: { continuation.yield($0) },
            routes: { stream }
        )
    }()

    static let testValue = Self(
        present: unimplemented("AppRouter.present"),
        routes: unimplemented("AppRouter.routes", placeholder: .finished)
    )
}

extension DependencyValues {
    var appRouter: AppRouter {
        get { self[AppRouter.self] }
        set { self[AppRouter.self] = newValue }
    }
}

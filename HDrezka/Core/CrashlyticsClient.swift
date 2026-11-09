import Dependencies
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import Foundation
import Synchronization

struct CrashlyticsClient {
    var configure: @MainActor @Sendable () -> Void
    var record: @Sendable (any Error) -> Void
    var log: @Sendable (String) -> Void
    var didCrashDuringPreviousExecution: @Sendable () async throws -> Bool
}

extension CrashlyticsClient: DependencyKey {
    static let liveValue: Self = {
        let buffer = CrashlyticsBuffer()

        return Self(
            configure: {
                guard !buffer.isReady else { return }

                UserDefaults.standard.register(
                    defaults: ["NSApplicationCrashOnExceptions": true],
                )

                #if DEBUG
                    FirebaseConfiguration.shared.setLoggerLevel(.max)
                #endif

                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }

                Crashlytics.crashlytics().setUserID(Const.deviceUUID)
                Analytics.setUserID(Const.deviceUUID)

                #if DEBUG
                    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
                    Analytics.setAnalyticsCollectionEnabled(false)
                #endif

                buffer.activate(
                    didCrash: Crashlytics.crashlytics().didCrashDuringPreviousExecution(),
                    sink: { event in
                        switch event {
                        case let .error(error):
                            Crashlytics.crashlytics().record(error: error)
                        case let .log(message):
                            Crashlytics.crashlytics().log(message)
                        }
                    },
                )
            },
            record: { buffer.append(.error($0)) },
            log: { buffer.append(.log($0)) },
            didCrashDuringPreviousExecution: { try await buffer.previousCrash() },
        )
    }()
}

extension DependencyValues {
    var crashlyticsClient: CrashlyticsClient {
        get { self[CrashlyticsClient.self] }
        set { self[CrashlyticsClient.self] = newValue }
    }
}

final class CrashlyticsBuffer: Sendable {
    enum Event {
        case error(any Error)
        case log(String)
    }

    private struct State {
        var sink: (@Sendable (Event) -> Void)?
        var didCrash = false
        var pending: [Event] = []
        var waiters: [UUID: CheckedContinuation<Bool, any Error>] = [:]
    }

    private let state = Mutex(State())

    var isReady: Bool {
        state.withLock { $0.sink != nil }
    }

    func append(_ event: Event) {
        state.withLock { state in
            if let sink = state.sink {
                sink(event)

                return
            }

            state.pending.append(event)
        }
    }

    func activate(didCrash: Bool, sink: @escaping @Sendable (Event) -> Void) {
        let continuations = state.withLock { state -> [CheckedContinuation<Bool, any Error>] in
            guard state.sink == nil else { return [] }

            state.didCrash = didCrash
            state.sink = sink

            state.pending.forEach(sink)
            state.pending.removeAll()

            defer { state.waiters.removeAll() }

            return Array(state.waiters.values)
        }

        for continuation in continuations {
            continuation.resume(returning: didCrash)
        }
    }

    func previousCrash() async throws -> Bool {
        let id = UUID()

        let result = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let immediate: Result<Bool, any Error>? = state.withLock { state in
                    if Task.isCancelled {
                        return .failure(CancellationError())
                    }

                    guard state.sink != nil else {
                        state.waiters[id] = continuation

                        return nil
                    }

                    return .success(state.didCrash)
                }

                if let immediate {
                    continuation.resume(with: immediate)
                }
            }
        } onCancel: {
            let continuation = state.withLock { $0.waiters.removeValue(forKey: id) }

            continuation?.resume(throwing: CancellationError())
        }

        try Task.checkCancellation()

        return result
    }
}

import Alamofire
import Dependencies
import Foundation
import UserNotifications

private enum SessionKey: DependencyKey {
    static var liveValue = Session(
        rootQueue: .init(label: "io.silentsea.hdrezka.rootQueue", qos: .userInitiated),
        startRequestsImmediately: false,
        interceptor: Interceptor(interceptors: [CustomInterceptor(), OfflineRetrier()]),
        redirectHandler: .modify { task, request, _ in
            var newRequest = task.originalRequest ?? task.currentRequest ?? request
            newRequest.url = request.url

            return newRequest
        },
        eventMonitors: [CustomMonitor()]
    )
}

extension DependencyValues {
    var session: Session {
        get { self[SessionKey.self] }
        set { self[SessionKey.self] = newValue }
    }
}

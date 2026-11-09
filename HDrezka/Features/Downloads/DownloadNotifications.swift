import Dependencies
import DependenciesMacros
import Foundation
import UserNotifications

enum DownloadNotification: Sendable {
    case downloading(DownloadData, gid: String)
    case succeeded(Download)
    case failed(DownloadData, reason: String? = nil)
    case canceled(Download)
    case needPremium(DownloadData)
}

private extension DownloadNotification {
    var data: DownloadData {
        switch self {
        case let .downloading(data, _), let .failed(data, _), let .needPremium(data):
            data
        case let .succeeded(download), let .canceled(download):
            download.data
        }
    }

    var content: UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default

        let name = data.name

        switch self {
        case let .downloading(_, gid):
            content.title = String(localized: "key.download.downloading")
            content.subtitle = String(localized: "key.download.downloading.notification-\(name)")
            content.categoryIdentifier = "cancel"
            content.userInfo = ["gid": gid]
        case let .succeeded(download):
            content.title = String(localized: "key.download.success")
            content.subtitle = String(localized: "key.download.success.notification-\(name)")
            content.categoryIdentifier = "open"
            content.userInfo = ["url": download.fileURL.absoluteString]
        case let .failed(_, reason):
            content.title = String(localized: "key.download.failed")
            content.subtitle = if let reason {
                String(localized: "key.download.failed.notification-\(name)-\(reason)")
            } else {
                String(localized: "key.download.failed.notification-\(name)")
            }
            retry(content)
        case .canceled:
            content.title = String(localized: "key.download.canceled")
            content.subtitle = String(localized: "key.download.canceled.notification-\(name)")
            retry(content)
        case .needPremium:
            content.title = String(localized: "key.download.needPremium")
            content.subtitle = String(localized: "key.download.needPremium.notification-\(name)")
            content.categoryIdentifier = "need_premium"
        }

        return content
    }

    func retry(_ content: UNMutableNotificationContent) {
        guard let retryData = data.retryData else { return }

        content.categoryIdentifier = "retry"
        content.userInfo = ["data": retryData]
    }
}

@DependencyClient
struct DownloadNotificationsClient: Sendable {
    var registerCategories: @Sendable () -> Void
    var post: @Sendable (_ notification: DownloadNotification) async -> Void
}

extension DownloadNotificationsClient: DependencyKey {
    static let liveValue = Self(
        registerCategories: {
            let categories = [
                ("open", String(localized: "key.open")),
                ("cancel", String(localized: "key.cancel")),
                ("retry", String(localized: "key.retry")),
                ("need_premium", String(localized: "key.buy")),
            ]

            UNUserNotificationCenter.current().setNotificationCategories(Set(categories.map { id, title in
                UNNotificationCategory(identifier: id, actions: [UNNotificationAction(identifier: id, title: title)], intentIdentifiers: [])
            }))
        },
        post: { notification in
            await post(UNNotificationRequest(identifier: notification.data.notificationId, content: notification.content, trigger: nil))
        },
    )

    private static func post(_ request: UNNotificationRequest) async {
        let center = UNUserNotificationCenter.current()

        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional:
            try? await center.add(request)
        case .notDetermined:
            if await (try? center.requestAuthorization(options: [.alert, .badge, .sound])) == true {
                try? await center.add(request)
            }
        default:
            break
        }
    }
}

extension DependencyValues {
    var downloadNotifications: DownloadNotificationsClient {
        get { self[DownloadNotificationsClient.self] }
        set { self[DownloadNotificationsClient.self] = newValue }
    }
}

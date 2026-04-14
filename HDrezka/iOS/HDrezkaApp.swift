import Combine
import Defaults
import FactoryKit
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import Kingfisher
import SwiftData
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        FirebaseApp.configure()
        Crashlytics.crashlytics().setUserID(Const.deviceUUID)
        Analytics.setUserID(Const.deviceUUID)

        #if DEBUG
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
            FirebaseConfiguration.shared.setLoggerLevel(.min)
            Analytics.setAnalyticsCollectionEnabled(false)
        #endif

        return true
    }

    func applicationWillTerminate(_: UIApplication) {
        if !Downloader.shared.downloads.isEmpty {
            let notificationCenter = UNUserNotificationCenter.current()

            notificationCenter.getPendingNotificationRequests { requests in
                notificationCenter.removePendingNotificationRequests(withIdentifiers: requests.filter { $0.content.categoryIdentifier == "cancel" }.map(\.identifier))
            }

            notificationCenter.getDeliveredNotifications { notifications in
                notificationCenter.removeDeliveredNotifications(withIdentifiers: notifications.filter { $0.request.content.categoryIdentifier == "cancel" }.map(\.request.identifier))
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound, .badge])
    }

    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case "cancel":
            if let id = userInfo["id"] as? String, let download = Downloader.shared.downloads.first(where: { $0.id == id }) {
                download.cancel()
            }
        case "open":
            if let url = userInfo["url"] as? String, let redirectURL = URL(string: url), UIApplication.shared.canOpenURL(redirectURL) {
                UIApplication.shared.open(redirectURL)
            }
        case "retry":
            if let retryData = userInfo["data"] as? Data, let data = try? JSONDecoder().decode(DownloadData.self, from: retryData) {
                Downloader.shared.download(data)
            }
        case "need_premium":
            if UIApplication.shared.canOpenURL((!Defaults.Keys.mirror.isDefaultValue ? Defaults[.mirror] : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory)) {
                UIApplication.shared.open((!Defaults.Keys.mirror.isDefaultValue ? Defaults[.mirror] : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory))
            }
        default:
            break
        }

        completionHandler()
    }
}

@main
struct HDrezkaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var appState: AppState = .shared
    @State private var downloader: Downloader = .shared
    @State private var cookiesManager: CookiesManager = .shared

    @Default(.theme) private var theme
    @Default(.isFirstLaunch) private var isFirstLaunch
    @Default(.mirror) private var mirror

    @Injected(\.modelContainer) private var modelContainer

    init() {
        switch Defaults[.cache] {
        case .off:
            ImageCache.default.memoryStorage.config.expiration = .expired
            ImageCache.default.diskStorage.config.expiration = .expired
        case .memory:
            ImageCache.default.diskStorage.config.expiration = .expired
        case .disk:
            ImageCache.default.memoryStorage.config.expiration = .expired
        case .all:
            break
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(downloader)
                .environment(cookiesManager)
                .preferredColorScheme(theme.scheme)
        }
        .modelContainer(modelContainer)
        .commands(content: customCommands)
        .commands(content: removed)
    }

    @CommandsBuilder
    func customCommands() -> some Commands {
        CommandGroup(replacing: .help) {
            Link(destination: Const.github) {
                Text("key.github")
            }

            Link(destination: (!_mirror.isDefaultValue ? mirror : Const.redirectMirror).appending(path: "rules/", directoryHint: .notDirectory)) {
                Text("key.site.rules")
            }

            Button {
                isFirstLaunch = true
            } label: {
                Text("key.disclaimer")
            }
        }
    }

    @CommandsBuilder
    func removed() -> some Commands {
        CommandGroup(replacing: .importExport) {}
        CommandGroup(replacing: .newItem) {}
        CommandGroup(replacing: .printItem) {}
        CommandGroup(replacing: .saveItem) {}
        CommandGroup(replacing: .sidebar) {}
        CommandGroup(replacing: .systemServices) {}
        CommandGroup(replacing: .toolbar) {}
    }
}

import Combine
import Defaults
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import SwiftData
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        UserDefaults.standard.register(
            defaults: ["NSApplicationCrashOnExceptions": true],
        )

        FirebaseApp.configure()

        #if DEBUG
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
            FirebaseConfiguration.shared.setLoggerLevel(.min)
            Analytics.setAnalyticsCollectionEnabled(false)
        #endif

        return true
    }

//    func applicationWillTerminate(_: Notification) {
//        if !Downloader.shared.downloads.isEmpty {
//            let notificationCenter = UNUserNotificationCenter.current()
//
//            notificationCenter.getPendingNotificationRequests { requests in
//                notificationCenter.removePendingNotificationRequests(withIdentifiers: requests.filter { $0.content.categoryIdentifier == "cancel" }.map(\.identifier))
//            }
//
//            notificationCenter.getDeliveredNotifications { notifications in
//                notificationCenter.removeDeliveredNotifications(withIdentifiers: notifications.filter { $0.request.content.categoryIdentifier == "cancel" }.map(\.request.identifier))
//            }
//        }
//
//        Downloader.shared.terminate()
//    }
//
//    func application(_: NSApplication, willEncodeRestorableState _: NSCoder) {}
//
//    func application(_: NSApplication, didDecodeRestorableState _: NSCoder) {}

    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound, .badge])
    }
//
//    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        let userInfo = response.notification.request.content.userInfo
//
//        switch response.actionIdentifier {
//        case "cancel":
//            if let gid = userInfo["gid"] as? String {
//                Downloader.shared.remove(gid)
//            }
//        case "open":
//            if let url = userInfo["url"] as? String, let fileUrl = URL(string: url), fileUrl.isFileURL {
//                NSWorkspace.shared.activateFileViewerSelecting([fileUrl])
//            }
//        case "retry":
//            if let retryData = userInfo["data"] as? Data, let data = try? JSONDecoder().decode(DownloadData.self, from: retryData) {
//                Downloader.shared.download(data)
//            }
//        case "need_premium":
//            NSWorkspace.shared.open((Defaults[.mirror] != Defaults.Keys.mirror.defaultValue ? Defaults[.mirror] : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory))
//        default:
//            break
//        }
//
//        completionHandler()
//    }
}

@main
struct HDrezkaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var appState: AppState = .shared

    @State private var modelContainer: ModelContainer

    @Default(.theme) private var theme

    init() {
        do {
            let schema = Schema([PlayerPosition.self, SelectPosition.self])
            let modelContainer = try ModelContainer(for: schema)
            modelContainer.mainContext.autosaveEnabled = true
            self.modelContainer = modelContainer
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(theme.scheme)
        }
        .modelContainer(modelContainer)
    }
}

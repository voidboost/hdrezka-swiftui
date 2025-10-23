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

        FirebaseApp.configure()

        #if DEBUG
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
            FirebaseConfiguration.shared.setLoggerLevel(.min)
            Analytics.setAnalyticsCollectionEnabled(false)
        #endif

        return true
    }

    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .sound, .badge])
    }
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

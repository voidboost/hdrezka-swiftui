import Combine
import Defaults
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import Kingfisher
import SwiftData
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        #if DEBUG
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
            FirebaseConfiguration.shared.setLoggerLevel(.min)
            Analytics.setAnalyticsCollectionEnabled(false)
        #endif

        return true
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

            let cache = ImageCache.default

            switch Defaults[.cache] {
            case .off:
                cache.memoryStorage.config.expiration = .expired
                cache.diskStorage.config.expiration = .expired
            case .memory:
                cache.diskStorage.config.expiration = .expired
            case .disk:
                cache.memoryStorage.config.expiration = .expired
            case .all:
                break
            }
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
        .commands(content: customCommands)
        .commands(content: removed)
    }

    @CommandsBuilder
    func customCommands() -> some Commands {
        CommandGroup(replacing: .help) {
            Link(destination: Const.github) {
                Text("key.github")
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

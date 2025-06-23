import Combine
import Defaults
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import Sparkle
import SwiftData
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        UNUserNotificationCenter.current().delegate = self

        NSWindow.allowsAutomaticWindowTabbing = false

        UserDefaults.standard.register(
            defaults: ["NSApplicationCrashOnExceptions": true],
        )

        FirebaseApp.configure()

        #if DEBUG
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
            FirebaseConfiguration.shared.setLoggerLevel(.min)
            Analytics.setAnalyticsCollectionEnabled(false)
        #endif
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        AppState.shared.path.removeAll()

        return Downloader.shared.downloads.isEmpty
    }

    func applicationWillTerminate(_: Notification) {
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

    func application(_: NSApplication, willEncodeRestorableState _: NSCoder) {}

    func application(_: NSApplication, didDecodeRestorableState _: NSCoder) {}

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
            if let url = userInfo["url"] as? String, let fileUrl = URL(string: url), fileUrl.isFileURL {
                NSWorkspace.shared.activateFileViewerSelecting([fileUrl])
            }
        case "retry":
            if let retryData = userInfo["data"] as? Data, let data = try? JSONDecoder().decode(DownloadData.self, from: retryData) {
                Downloader.shared.download(data)
            }
        case "need_premium":
            NSWorkspace.shared.open((Defaults[.mirror] != Defaults.Keys.mirror.defaultValue ? Defaults[.mirror] : Const.redirectMirror).appending(path: "payments", directoryHint: .notDirectory))
        default:
            break
        }

        completionHandler()
    }
}

@main
struct HDrezkaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var appState: AppState = .shared
    @State private var downloader: Downloader = .shared
    @Environment(\.openWindow) private var openWindow

    @State private var updaterController: SPUStandardUpdaterController
    @State private var modelContainer: ModelContainer

    @Default(.theme) private var theme

    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

        do {
            let schema = Schema([PlayerPosition.self, SelectPosition.self])
            let modelContainer = try ModelContainer(for: schema)
            modelContainer.mainContext.autosaveEnabled = true
            self.modelContainer = modelContainer

            Downloader.shared.setModelContext(modelContext: modelContainer.mainContext)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(downloader)
                .background(WindowAccessor { window in
                    appState.window = window
                })
                .preferredColorScheme(theme.scheme)
        }
        .modelContainer(modelContainer)
        .windowResizability(.contentMinSize)
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)
        .restorationBehavior(.disabled)
        .commands(content: customCommands)
        .commands(content: removed)

        WindowGroup("key.player", id: "player", for: PlayerData.self) { $data in
            if let data {
                PlayerView(data: data)
                    .environment(appState)
            }
        }
        .modelContainer(modelContainer)
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)
        .restorationBehavior(.disabled)
        .commands(content: customCommands)
        .commands(content: removed)

        WindowGroup("key.imageViewer", id: "imageViewer", for: URL.self) { $url in
            if let url {
                ImageView(url: url).preferredColorScheme(theme.scheme)
            }
        }
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)
        .restorationBehavior(.disabled)
        .commands(content: customCommands)
        .commands(content: removed)

        WindowGroup("key.licenses", id: "licenses") {
            LicensesView().preferredColorScheme(theme.scheme)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .commands(content: customCommands)
        .commands(content: removed)

        Settings {
            SettingsView(updater: updaterController.updater).preferredColorScheme(theme.scheme)
        }
        .modelContainer(modelContainer)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .restorationBehavior(.disabled)
        .commands(content: customCommands)
        .commands(content: removed)

        MenuBarExtra(isInserted: Binding {
            !downloader.downloads.isEmpty
        } set: { _ in }) {
            DownloadsView()
                .environment(downloader)
                .preferredColorScheme(theme.scheme)
        } label: {
            MenuBarIcon()
        }
        .menuBarExtraStyle(.window)
        .restorationBehavior(.disabled)
        .commands(content: customCommands)
        .commands(content: removed)
    }

    @CommandsBuilder
    func customCommands() -> some Commands {
        CommandGroup(replacing: .appSettings) {
            SettingsLink {
                Text("key.settings")
            }
            .keyboardShortcut(",", modifiers: .command)

            UpdateButton(updater: updaterController.updater)

            Button {
                openWindow(id: "licenses")
            } label: {
                Text("key.licenses")
            }
        }

        CommandGroup(replacing: .appInfo) {
            Button {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = NSTextAlignment.center

                if let image = NSImage(named: "GS") {
                    let imageAttachment = NSTextAttachment()
                    imageAttachment.image = image.resized(to: CGSize(width: 76, height: 100)).tint(NSColor(Color.accentColor))

                    let credits = NSMutableAttributedString(attachment: imageAttachment)
                    credits.addAttribute(.link, value: Const.helpUkraine, range: NSRange(location: 0, length: credits.length))
                    credits.append(NSAttributedString(string: "\n\n© 2025 "))
                    credits.append(NSAttributedString(string: "HDrezka macOS", attributes: [.link: Const.github]))
                    credits.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: credits.length))

                    NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
                } else {
                    let credits = NSMutableAttributedString(string: "© 2025 ")
                    credits.append(NSAttributedString(string: "HDrezka macOS", attributes: [.link: Const.github]))
                    credits.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: credits.length))

                    NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
                }
            } label: {
                Text("key.about-\(Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "HDrezka")")
            }
        }

        CommandGroup(replacing: .appTermination) {
            Button {
                NSApp.terminate(nil)
            } label: {
                Text("key.close-\(Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "HDrezka")")
            }
            .keyboardShortcut("q", modifiers: .command)
        }

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
        CommandGroup(replacing: .singleWindowList) {}
        CommandGroup(replacing: .systemServices) {}
        CommandGroup(replacing: .toolbar) {}
        CommandGroup(replacing: .windowList) {}
    }

    private struct MenuBarIcon: View {
        var body: some View {
            if let image = NSImage(named: "BarIcon") {
                Image(nsImage: image.resized(to: CGSize(width: 18, height: 18)))
            } else {
                Image(systemName: "list.and.film")
            }
        }
    }
}

import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isSignInPresented = false
    @Published var isSignUpPresented = false
    @Published var isRestorePresented = false
    @Published var isSignOutPresented = false

    @Published var commentsRulesPresented = false

    @Published var isPremiumPresented = false

    @Published var path: [Destinations] = []

    @Published var window: NSWindow?
}

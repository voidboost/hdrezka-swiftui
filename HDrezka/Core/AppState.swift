import SwiftUI

@Observable
class AppState {
    @ObservationIgnored
    static let shared = AppState()

    var isSignInPresented = false
    var isSignUpPresented = false
    var isRestorePresented = false
    var isSignOutPresented = false

    var commentsRulesPresented = false

    var isPremiumPresented = false

    var path: [Destinations] = []

    var window: NSWindow?
}

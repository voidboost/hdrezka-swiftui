import SwiftUI

enum ExternalDownloaders: Int, CaseIterable, Identifiable {
    case folx = 0
    case motrix

    var id: Self { self }

    var url: URL {
        switch self {
        case .folx:
            URL(string: "openinfolx3://downloadAllWithFolx")!
        case .motrix:
            URL(string: "motrix://new-task")!
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .folx:
            "com.eltima.Folx3"
        case .motrix:
            "app.motrix.native"
        }
    }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .folx:
            "key.download.folx"
        case .motrix:
            "key.download.motrix"
        }
    }
}

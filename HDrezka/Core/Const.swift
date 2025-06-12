import Alamofire
import Defaults
import Foundation
import SwiftUI

class Const {
    static let mirror = URL(string: "https://hdrzk.org/")!

    static let redirectMirror = URL(string: "https://rzk.link/")!

    static let details = URL(string: "hdrezka://details/")!

    static let github = URL(string: "https://github.com/voidboost/hdrezka-macos")!

    static let helpUkraine = URL(string: "https://u24.gov.ua/")!

    static let fakeUpdate = URL(string: "https://api.hdrezka.tech/")!

    static let lastHdrezkaAppVersion = "2.2.2"

    static let premiumGradient = LinearGradient(colors: [
        .init(red: 222.0 / 255.0, green: 21.0 / 255.0, blue: 226.0 / 255.0),
        .init(red: 138.0 / 255.0, green: 0.0, blue: 173.0 / 255.0)
    ], startPoint: .leading, endPoint: .trailing)

    static var userAgent: String {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "HDrezka"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let appBundle = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let osName = "macOS"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion

        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let deviceModel = String(cString: model)

        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        if service != 0 {
            defer { IOObjectRelease(service) }

            if let uuid = IORegistryEntryCreateCFProperty(service, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String, !uuid.isEmpty {
                return "\(appName)/\(appVersion)(\(appBundle)) (\(deviceModel); \(osName) \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion); \(uuid))"
            }
        }

        return "\(appName)/\(appVersion)(\(appBundle)) (\(deviceModel); \(osName) \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion))"
    }

    static var headers: HTTPHeaders {
        HTTPHeaders(
            Defaults[.useHeaders] ? [
                .init(name: "X-Hdrezka-Android-App", value: "1"),
                .init(name: "X-Hdrezka-Android-App-Version", value: Defaults[.lastHdrezkaAppVersion]),
                .userAgent(userAgent)
            ] : [.userAgent(userAgent)]
        )
    }
}

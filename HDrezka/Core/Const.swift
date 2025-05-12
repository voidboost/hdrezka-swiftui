import Alamofire
import Defaults
import Foundation
import SwiftUI

class Const {
    static let mirror = "https://hdrzk.org/"

    static let redirectMirror = "https://rzk.link/"

    static let details = "hdrezka://details/"

    static let telegram = "https://hdrezka_macos.t.me/"

    static let helpUkraine = "https://u24.gov.ua/"

    static let fakeUpdate = "https://api.hdrezka.tech/"

    static let lastHdrezkaAppVersion = "2.2.2"

    static let premiumGradient = LinearGradient(colors: [
        .init(red: 222.0 / 255.0, green: 21.0 / 255.0, blue: 226.0 / 255.0),
        .init(red: 138.0 / 255.0, green: 0.0, blue: 173.0 / 255.0),
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
            if let uuid = IORegistryEntryCreateCFProperty(service, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String, !uuid.isEmpty {
                IOObjectRelease(service)

                return "\(appName)/\(appVersion)(\(appBundle)) (\(deviceModel); \(osName) \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion); \(uuid))"
            }
            IOObjectRelease(service)
        }

        return "\(appName)/\(appVersion)(\(appBundle)) (\(deviceModel); \(osName) \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion))"
    }

    static var headers: HTTPHeaders {
        HTTPHeaders(
            Defaults[.useHeaders] ? [
                "X-Hdrezka-Android-App": "1",
                "X-Hdrezka-Android-App-Version": Defaults[.lastHdrezkaAppVersion],
                "User-Agent": userAgent
            ] : ["User-Agent": userAgent]
        )
    }

    static let session = Session(
        startRequestsImmediately: false,
        interceptor: CustomInterceptor(),
        redirectHandler: .modify { task, request, _ in
            var newRequest = task.originalRequest ?? task.currentRequest ?? request
            newRequest.url = request.url

            return newRequest
        },
        eventMonitors: [CustomMonitor()]
    )
}

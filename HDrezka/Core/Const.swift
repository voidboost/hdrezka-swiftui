import Alamofire
import Defaults
import Dependencies
import Foundation
import SwiftUI

class Const {
    static let mirror = URL(string: "https://hdrzk.org/")!

    static let redirectMirror = URL(string: "https://rzk.link/")!

    static let github = URL(string: "https://github.com/voidboost/hdrezka-swiftui")!

    static let helpUkraine = URL(string: "https://u24.gov.ua/")!

    static let fakeUpdate = URL(string: "https://api.hdrezka.tech/")!

    static let rpcPort = freePort() ?? 6800

    static let rpc = URL(string: "http://127.0.0.1:\(rpcPort)/")!

    static let token = UUID().uuidString

    static let lastHdrezkaAppVersion = "2.2.2"

    static let premiumGradient = LinearGradient(colors: [
        .init(red: 222.0 / 255.0, green: 21.0 / 255.0, blue: 226.0 / 255.0),
        .init(red: 138.0 / 255.0, green: 0.0, blue: 173.0 / 255.0),
    ], startPoint: .leading, endPoint: .trailing)

    static let userAgent: String = {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "HDrezka"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let appBundle = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let osName = "macOS"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion

        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let deviceModel = String(utf8String: model) ?? "Unknown"

        return "\(appName)/\(appVersion)(\(appBundle)) (\(deviceModel); \(osName) \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion); \(Const.deviceUUID))"
    }()

    static var deviceUUID: String {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        if service != 0 {
            defer { IOObjectRelease(service) }

            if let uuid = IORegistryEntryCreateCFProperty(service, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String, !uuid.isEmpty {
                return uuid.uppercased()
            }
        }

        if let uuid = Defaults[.deviceUUID], !uuid.isEmpty {
            return uuid.uppercased()
        }

        let uuid = UUID().uuidString.uppercased()
        Defaults[.deviceUUID] = uuid
        return uuid
    }

    static var headers: HTTPHeaders {
        HTTPHeaders(
            Defaults[.useHeaders] ? [
                .init(name: "X-Hdrezka-Android-App", value: "1"),
                .init(name: "X-Hdrezka-Android-App-Version", value: Defaults[.lastHdrezkaAppVersion]),
                .userAgent(userAgent),
            ] : [.userAgent(userAgent)]
        )
    }

    private static func freePort() -> Int? {
        let socket = Darwin.socket(AF_INET, SOCK_STREAM, 0)

        guard socket >= 0 else { return nil }

        defer { close(socket) }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        address.sin_port = 0

        var length = socklen_t(MemoryLayout<sockaddr_in>.size)

        let bound = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(socket, $0, length) == 0 && getsockname(socket, $0, &length) == 0
            }
        }

        guard bound else { return nil }

        return Int(UInt16(bigEndian: address.sin_port))
    }

    static var dbPath: String {
        get throws {
            let applicationSupportDirectory = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            return applicationSupportDirectory.appending(path: "HDrezka.db", directoryHint: .notDirectory).absoluteString
        }
    }
}

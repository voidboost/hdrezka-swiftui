import Defaults
import Dependencies
import Foundation

@Observable
@MainActor
class CookiesManager {
    @ObservationIgnored static let shared = CookiesManager()

    @ObservationIgnored private var observation: Task<Void, Never>?

    @ObservationIgnored @Dependency(\.notificationCenter) private var notificationCenter

    init() {
        observe()
    }

    private func observe() {
        observation = Task { [weak self, notificationCenter] in
            for await _ in notificationCenter.notifications(named: .NSHTTPCookieManagerCookiesChanged, object: HTTPCookieStorage.shared) {
                guard self != nil, let cookies = HTTPCookieStorage.shared.cookies(for: Defaults[.mirror]) else { continue }

                if cookies.contains(where: { $0.name == "dle_user_id" }),
                   cookies.contains(where: { $0.name == "dle_password" })
                {
                    Defaults[.isLoggedIn] = true
                } else {
                    Defaults[.isLoggedIn] = false
                    Defaults[.isUserPremium] = nil
                }

                Defaults[.allowedComments] = cookies.contains { $0.name == "allowed_comments" && $0.value == "1" }
            }
        }
    }

    func setMirror(_ mirror: URL) {
        observation?.cancel()

        defer { observe() }

        if Defaults[.isLoggedIn],
           let cookies = HTTPCookieStorage.shared.cookies(for: Defaults[.mirror]),
           !cookies.isEmpty,
           let host = mirror.host(),
           !host.isEmpty
        {
            let newDomain = ".\(host)"

            let newCookies: [HTTPCookie] = cookies.compactMap { cookie in
                guard var properties = cookie.properties else { return nil }

                properties[.domain] = newDomain

                return HTTPCookie(properties: properties)
            }

            cookies.forEach(HTTPCookieStorage.shared.deleteCookie)
            newCookies.forEach(HTTPCookieStorage.shared.setCookie)
        }

        Defaults[.mirror] = mirror
    }

    func allowComments() {
        if let host = Defaults[.mirror].host(),
           !host.isEmpty,
           let cookie = HTTPCookie(properties: [
               .name: "allowed_comments",
               .value: "1",
               .domain: ".\(host)",
               .path: "/",
               .expires: Date(timeIntervalSinceNow: 60 * 60 * 24 * 30),
           ])
        {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }
}

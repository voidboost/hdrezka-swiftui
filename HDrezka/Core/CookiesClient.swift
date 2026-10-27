import Defaults
import Dependencies
import Foundation

struct CookiesClient: Sendable {
    var observe: @Sendable () async -> Void
    var setMirror: @Sendable (URL) -> Void
    var allowComments: @Sendable () -> Void
}

extension CookiesClient: DependencyKey {
    static let liveValue = Self(
        observe: {
            @Dependency(\.notificationCenter) var notificationCenter

            for await _ in notificationCenter.notifications(named: .NSHTTPCookieManagerCookiesChanged, object: HTTPCookieStorage.shared) {
                guard let cookies = HTTPCookieStorage.shared.cookies(for: Defaults[.mirror]) else { continue }

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
        },
        setMirror: { mirror in
            guard Defaults[.isLoggedIn],
                  let cookies = HTTPCookieStorage.shared.cookies(for: Defaults[.mirror]),
                  !cookies.isEmpty,
                  let host = mirror.host(),
                  !host.isEmpty
            else {
                Defaults[.mirror] = mirror

                return
            }

            let newDomain = ".\(host)"

            let newCookies: [HTTPCookie] = cookies.compactMap { cookie in
                guard var properties = cookie.properties else { return nil }

                properties[.domain] = newDomain

                return HTTPCookie(properties: properties)
            }

            newCookies.forEach(HTTPCookieStorage.shared.setCookie)

            Defaults[.mirror] = mirror

            cookies.filter { $0.domain != newDomain }.forEach(HTTPCookieStorage.shared.deleteCookie)
        },
        allowComments: {
            guard let host = Defaults[.mirror].host(),
                  !host.isEmpty,
                  let cookie = HTTPCookie(properties: [
                      .name: "allowed_comments",
                      .value: "1",
                      .domain: ".\(host)",
                      .path: "/",
                      .expires: Date(timeIntervalSinceNow: 60 * 60 * 24 * 30),
                  ])
            else {
                return
            }

            HTTPCookieStorage.shared.setCookie(cookie)
        }
    )
}

extension DependencyValues {
    var cookiesClient: CookiesClient {
        get { self[CookiesClient.self] }
        set { self[CookiesClient.self] = newValue }
    }
}

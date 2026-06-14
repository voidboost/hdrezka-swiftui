import Combine
import Defaults
import Foundation

@Observable
class CookiesManager {
    @ObservationIgnored static let shared = CookiesManager()

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    init() {
        observe()
    }

    private func observe() {
        NotificationCenter.default.publisher(for: .NSHTTPCookieManagerCookiesChanged, object: HTTPCookieStorage.shared)
            .compactMap { $0.object as? HTTPCookieStorage }
            .compactMap { $0.cookies(for: Defaults[.mirror]) }
            .receive(on: DispatchQueue.main)
            .sink { cookies in
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
            .store(in: &subscriptions)
    }

    func setMirror(_ mirror: URL) {
        subscriptions.flush()

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

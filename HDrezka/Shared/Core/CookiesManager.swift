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

                Defaults[.allowedComments] = cookies.contains { $0.name == "allowed_comments" }
            }
            .store(in: &subscriptions)
    }

    func migrateCookies(from: URL, to: URL, completion: @escaping () -> Void) {
        guard Defaults[.isLoggedIn],
              let cookies = HTTPCookieStorage.shared.cookies(for: from),
              !cookies.isEmpty,
              let host = to.host(),
              !host.isEmpty
        else {
            return
        }

        subscriptions.flush()

        defer { observe() }

        let newDomain = ".\(host)"

        let newCookies: [HTTPCookie] = cookies.compactMap { cookie in
            guard var properties = cookie.properties else { return nil }

            properties[.domain] = newDomain

            return HTTPCookie(properties: properties)
        }

        cookies.forEach(HTTPCookieStorage.shared.deleteCookie)
        newCookies.forEach(HTTPCookieStorage.shared.setCookie)

        completion()
    }

    func allowComments() {
        if let host = Defaults[.mirror].host(),
           !host.isEmpty,
           let cookie = HTTPCookie(properties: [
               .name: "allowed_comments",
               .value: "1",
               .domain: ".\(host)",
               .path: "/",
               .expires: Date(timeIntervalSinceNow: 30 * 24 * 60 * 60),
           ])
        {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }
}

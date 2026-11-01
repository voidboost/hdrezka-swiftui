import Alamofire
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct PeopleClient: Sendable {
    var getPersonDetails: @Sendable (_ id: String) async throws -> PersonDetailed
}

extension PeopleClient: DependencyKey {
    static let liveValue: Self = {
        @Dependency(\.session) var session

        return Self(
            getPersonDetails: { id in
                try await session.page(PeopleService.getPersonDetails(id: id.replacingOccurrences(of: "person/", with: "").replacingOccurrences(of: "/", with: "")), parse: PeopleParser.parse)
            }
        )
    }()

    static let testValue = Self()
}

extension DependencyValues {
    var peopleClient: PeopleClient {
        get { self[PeopleClient.self] }
        set { self[PeopleClient.self] = newValue }
    }
}

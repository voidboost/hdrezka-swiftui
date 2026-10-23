import Alamofire
import Dependencies
import Foundation

struct PeopleRepositoryImpl: PeopleRepository {
    @Dependency(\.session) private var session

    func getPersonDetails(id: String) async throws -> PersonDetailed {
        try await session.string(PeopleService.getPersonDetails(id: id.replacingOccurrences(of: "person/", with: "").replacingOccurrences(of: "/", with: "")), parse: PeopleParser.parse)
    }
}

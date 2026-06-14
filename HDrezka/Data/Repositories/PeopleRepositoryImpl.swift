import Alamofire
import Combine
import FactoryKit
import Foundation

struct PeopleRepositoryImpl: PeopleRepository {
    @Injected(\.session) private var session

    func getPersonDetails(id: String) -> AnyPublisher<PersonDetailed, Error> {
        session.request(PeopleService.getPersonDetails(id: id.replacingOccurrences(of: "person/", with: "").replacingOccurrences(of: "/", with: "")))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(PeopleParser.parse)
            .handleError()
            .eraseToAnyPublisher()
    }
}

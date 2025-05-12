import Alamofire
import Combine
import Foundation

protocol PeopleRepository {
    func getPersonDetails(id: String) -> AnyPublisher<PersonDetailed, Error>
}

struct PeopleRepositoryImpl: PeopleRepository {
    func getPersonDetails(id: String) -> AnyPublisher<PersonDetailed, Error> {
        Const.session.request(PeopleService.getPersonDetails(id: id.replacingOccurrences(of: "person/", with: "").replacingOccurrences(of: "/", with: "")))
            .validate(statusCode: 200 ..< 400)
            .publishString()
            .value()
            .tryMap(PeopleParser.parse)
            .handleError()
            .eraseToAnyPublisher()
    }
}

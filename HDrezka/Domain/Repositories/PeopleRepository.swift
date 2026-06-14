import Combine

protocol PeopleRepository {
    func getPersonDetails(id: String) -> AnyPublisher<PersonDetailed, Error>
}

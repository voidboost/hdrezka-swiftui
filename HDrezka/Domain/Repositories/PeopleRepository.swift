import Combine
import Dependencies

protocol PeopleRepository {
    func getPersonDetails(id: String) -> AnyPublisher<PersonDetailed, Error>
}

private enum PeopleRepositoryKey: DependencyKey {
    static var liveValue: any PeopleRepository = PeopleRepositoryImpl()
}

extension DependencyValues {
    var peopleRepository: any PeopleRepository {
        get { self[PeopleRepositoryKey.self] }
        set { self[PeopleRepositoryKey.self] = newValue }
    }
}

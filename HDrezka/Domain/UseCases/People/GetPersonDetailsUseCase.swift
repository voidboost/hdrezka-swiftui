import Combine

struct GetPersonDetailsUseCase {
    private let repository: PeopleRepository

    init(repository: PeopleRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String) -> AnyPublisher<PersonDetailed, Error> {
        repository.getPersonDetails(id: id)
    }
}

import Combine
import Dependencies

struct GetPersonDetailsUseCase {
    @Dependency(\.peopleRepository) private var repository

    func callAsFunction(id: String) -> AnyPublisher<PersonDetailed, Error> {
        repository.getPersonDetails(id: id)
    }
}

extension GetPersonDetailsUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getPersonDetailsUseCase: GetPersonDetailsUseCase {
        get { self[GetPersonDetailsUseCase.self] }
        set { self[GetPersonDetailsUseCase.self] = newValue }
    }
}

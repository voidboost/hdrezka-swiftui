import Dependencies

struct GetPersonDetailsUseCase {
    @Dependency(\.peopleRepository) private var repository

    func callAsFunction(id: String) async throws -> PersonDetailed {
        try await repository.getPersonDetails(id: id)
    }
}

extension GetPersonDetailsUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getPersonDetailsUseCase: GetPersonDetailsUseCase {
        get { self[GetPersonDetailsUseCase.self] }
        set { self[GetPersonDetailsUseCase.self] = newValue }
    }
}

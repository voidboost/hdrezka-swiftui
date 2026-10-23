import Dependencies

struct GetVersionUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction() async throws -> String {
        try await repository.getVersion()
    }
}

extension GetVersionUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getVersionUseCase: GetVersionUseCase {
        get { self[GetVersionUseCase.self] }
        set { self[GetVersionUseCase.self] = newValue }
    }
}

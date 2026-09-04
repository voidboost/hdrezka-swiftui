import Combine
import Dependencies

struct GetVersionUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction() -> AnyPublisher<String, Error> {
        repository.getVersion()
    }
}

extension GetVersionUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getVersionUseCase: GetVersionUseCase {
        get { self[GetVersionUseCase.self] }
        set { self[GetVersionUseCase.self] = newValue }
    }
}

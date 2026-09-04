import Combine
import Dependencies

struct RestoreUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(login: String) -> AnyPublisher<String?, Error> {
        repository.restore(login: login)
    }
}

extension RestoreUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var restoreUseCase: RestoreUseCase {
        get { self[RestoreUseCase.self] }
        set { self[RestoreUseCase.self] = newValue }
    }
}

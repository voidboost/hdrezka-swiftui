import Combine
import Dependencies

struct LogoutUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction() -> AnyPublisher<Bool, Error> {
        repository.logout()
    }
}

extension LogoutUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var logoutUseCase: LogoutUseCase {
        get { self[LogoutUseCase.self] }
        set { self[LogoutUseCase.self] = newValue }
    }
}

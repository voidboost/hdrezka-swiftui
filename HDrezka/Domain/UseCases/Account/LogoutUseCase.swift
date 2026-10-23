import Dependencies

struct LogoutUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction() async throws -> Bool {
        try await repository.logout()
    }
}

extension LogoutUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var logoutUseCase: LogoutUseCase {
        get { self[LogoutUseCase.self] }
        set { self[LogoutUseCase.self] = newValue }
    }
}

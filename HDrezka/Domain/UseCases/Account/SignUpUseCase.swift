import Dependencies

struct SignUpUseCase {
    @Dependency(\.accountRepository) private var repository

    func callAsFunction(email: String, login: String, password: String, verifyCode: String, step: Int) async throws {
        try await repository.signUp(email: email, login: login, password: password, verifyCode: verifyCode, step: step)
    }
}

extension SignUpUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var signUpUseCase: SignUpUseCase {
        get { self[SignUpUseCase.self] }
        set { self[SignUpUseCase.self] = newValue }
    }
}

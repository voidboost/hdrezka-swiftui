import Dependencies

struct CallUseCase {
    @Dependency(\.aria2Repository) private var repository

    func callAsFunction<D: Decodable & Sendable>(data: some Encodable & Sendable) async throws -> Aria2Response<D> {
        try await repository.call(data: data)
    }
}

extension CallUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var callUseCase: CallUseCase {
        get { self[CallUseCase.self] }
        set { self[CallUseCase.self] = newValue }
    }
}

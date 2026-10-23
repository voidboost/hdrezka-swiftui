import Dependencies

struct MulticallUseCase {
    @Dependency(\.aria2Repository) private var repository

    func callAsFunction<D: Decodable & Sendable>(data: [some Encodable & Sendable]) async throws -> [Aria2Response<D>] {
        try await repository.multicall(data: data)
    }
}

extension MulticallUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var multicallUseCase: MulticallUseCase {
        get { self[MulticallUseCase.self] }
        set { self[MulticallUseCase.self] = newValue }
    }
}

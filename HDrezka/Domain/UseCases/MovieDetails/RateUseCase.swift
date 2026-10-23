import Dependencies

struct RateUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(id: String, rating: Int) async throws -> (Float?, String?)? {
        try await repository.rate(id: id, rating: rating)
    }
}

extension RateUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var rateUseCase: RateUseCase {
        get { self[RateUseCase.self] }
        set { self[RateUseCase.self] = newValue }
    }
}

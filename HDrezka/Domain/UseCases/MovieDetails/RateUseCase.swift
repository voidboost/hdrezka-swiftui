import Combine
import Dependencies

struct RateUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(id: String, rating: Int) -> AnyPublisher<(Float?, String?)?, Error> {
        repository.rate(id: id, rating: rating)
    }
}

extension RateUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var rateUseCase: RateUseCase {
        get { self[RateUseCase.self] }
        set { self[RateUseCase.self] = newValue }
    }
}

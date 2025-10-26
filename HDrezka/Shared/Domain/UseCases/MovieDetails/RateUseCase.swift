import Combine

struct RateUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String, rating: Int) -> AnyPublisher<(Float?, String?)?, Error> {
        repository.rate(id: id, rating: rating)
    }
}

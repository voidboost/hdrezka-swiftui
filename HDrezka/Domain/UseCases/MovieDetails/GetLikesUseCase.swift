import Combine

struct GetLikesUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String) -> AnyPublisher<[Like], Error> {
        repository.getLikes(id: id)
    }
}

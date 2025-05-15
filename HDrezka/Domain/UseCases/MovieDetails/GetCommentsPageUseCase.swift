import Combine

struct GetCommentsPageUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(movieId: String, page: Int) -> AnyPublisher<[Comment], Error> {
        repository.getCommentsPage(movieId: movieId, page: page)
    }
}

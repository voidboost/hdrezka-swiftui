import Combine

struct CategoriesUseCase {
    private let repository: SearchRepository

    init(repository: SearchRepository) {
        self.repository = repository
    }

    func callAsFunction() -> AnyPublisher<[MovieType], Error> {
        repository.categories()
    }
}

import Combine

struct GetMovieListUseCase {
    private let repository: MovieListsRepository

    init(repository: MovieListsRepository) {
        self.repository = repository
    }

    func callAsFunction(listId: String, page: Int) -> AnyPublisher<(String, [MovieSimple]), Error> {
        repository.getMovieList(listId: listId, page: page)
    }
}

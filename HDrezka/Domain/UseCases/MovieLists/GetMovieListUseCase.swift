import Combine
import Dependencies

struct GetMovieListUseCase {
    @Dependency(\.movieListsRepository) private var repository

    func callAsFunction(listId: String, page: Int) -> AnyPublisher<(String, [MovieSimple]), Error> {
        repository.getMovieList(listId: listId, page: page)
    }
}

extension GetMovieListUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getMovieListUseCase: GetMovieListUseCase {
        get { self[GetMovieListUseCase.self] }
        set { self[GetMovieListUseCase.self] = newValue }
    }
}

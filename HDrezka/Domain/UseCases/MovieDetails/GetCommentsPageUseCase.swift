import Combine
import Dependencies

struct GetCommentsPageUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(movieId: String, page: Int) -> AnyPublisher<[Comment], Error> {
        repository.getCommentsPage(movieId: movieId, page: page)
    }
}

extension GetCommentsPageUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getCommentsPageUseCase: GetCommentsPageUseCase {
        get { self[GetCommentsPageUseCase.self] }
        set { self[GetCommentsPageUseCase.self] = newValue }
    }
}

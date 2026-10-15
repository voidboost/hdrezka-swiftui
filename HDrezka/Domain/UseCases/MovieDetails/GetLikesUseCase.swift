import Combine
import Dependencies

struct GetLikesUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(id: String) -> AnyPublisher<[Like], Error> {
        repository.getLikes(id: id)
    }
}

extension GetLikesUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var getLikesUseCase: GetLikesUseCase {
        get { self[GetLikesUseCase.self] }
        set { self[GetLikesUseCase.self] = newValue }
    }
}

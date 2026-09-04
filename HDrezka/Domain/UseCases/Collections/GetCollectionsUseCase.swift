import Combine
import Dependencies

struct GetCollectionsUseCase {
    @Dependency(\.collectionsRepository) private var repository

    func callAsFunction(page: Int) -> AnyPublisher<[MoviesCollection], Error> {
        repository.getCollections(page: page)
    }
}

extension GetCollectionsUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var getCollectionsUseCase: GetCollectionsUseCase {
        get { self[GetCollectionsUseCase.self] }
        set { self[GetCollectionsUseCase.self] = newValue }
    }
}

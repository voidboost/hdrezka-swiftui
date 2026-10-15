import Combine
import Dependencies

struct CategoriesUseCase {
    @Dependency(\.searchRepository) private var repository

    func callAsFunction() -> AnyPublisher<[MovieType], Error> {
        repository.categories()
    }
}

extension CategoriesUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var categoriesUseCase: CategoriesUseCase {
        get { self[CategoriesUseCase.self] }
        set { self[CategoriesUseCase.self] = newValue }
    }
}

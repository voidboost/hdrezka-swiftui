import Dependencies

struct CategoriesUseCase {
    @Dependency(\.searchRepository) private var repository

    func callAsFunction() async throws -> [MovieType] {
        try await repository.categories()
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

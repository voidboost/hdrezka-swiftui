//import Combine
//import Dependencies
//
//struct GetFeaturedMoviesUseCase {
//    @Dependency(\.movieListsRepository) private var repository
//
//    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
//        repository.getFeaturedMovies(page: page, genre: genre)
//    }
//}
//
//extension GetFeaturedMoviesUseCase: DependencyKey {
//    static var liveValue = Self()
//}
//
//extension DependencyValues {
//    var getFeaturedMoviesUseCase: GetFeaturedMoviesUseCase {
//        get { self[GetFeaturedMoviesUseCase.self] }
//        set { self[GetFeaturedMoviesUseCase.self] = newValue }
//    }
//}

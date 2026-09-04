import Combine
import Dependencies

struct MulticallUseCase {
    @Dependency(\.aria2Repository) private var repository

    func callAsFunction<D: Decodable>(data: [some Encodable]) -> AnyPublisher<[Aria2Response<D>], Error> {
        repository.multicall(data: data)
    }
}

extension MulticallUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var multicallUseCase: MulticallUseCase {
        get { self[MulticallUseCase.self] }
        set { self[MulticallUseCase.self] = newValue }
    }
}

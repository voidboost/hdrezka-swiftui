import Combine
import Dependencies

struct CallUseCase {
    @Dependency(\.aria2Repository) private var repository

    func callAsFunction<D: Decodable>(data: some Encodable) -> AnyPublisher<Aria2Response<D>, Error> {
        repository.call(data: data)
    }
}

extension CallUseCase: DependencyKey {
    static var liveValue = Self()
}

extension DependencyValues {
    var callUseCase: CallUseCase {
        get { self[CallUseCase.self] }
        set { self[CallUseCase.self] = newValue }
    }
}

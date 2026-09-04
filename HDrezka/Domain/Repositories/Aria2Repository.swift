import Combine
import Dependencies

protocol Aria2Repository {
    func call<D: Decodable>(data: some Encodable) -> AnyPublisher<Aria2Response<D>, Error>

    func multicall<D: Decodable>(data: [some Encodable]) -> AnyPublisher<[Aria2Response<D>], Error>
}

private enum Aria2RepositoryKey: DependencyKey {
    static var liveValue: any Aria2Repository = Aria2RepositoryImpl()
}

extension DependencyValues {
    var aria2Repository: any Aria2Repository {
        get { self[Aria2RepositoryKey.self] }
        set { self[Aria2RepositoryKey.self] = newValue }
    }
}

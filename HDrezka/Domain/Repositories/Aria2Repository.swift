import Combine
import Dependencies

protocol Aria2Repository: Sendable {
    func call<D: Decodable & Sendable>(data: some Encodable & Sendable) -> AnyPublisher<Aria2Response<D>, Error>

    func multicall<D: Decodable & Sendable>(data: [some Encodable & Sendable]) -> AnyPublisher<[Aria2Response<D>], Error>
}

private enum Aria2RepositoryKey: DependencyKey {
    static let liveValue: any Aria2Repository = Aria2RepositoryImpl()
}

extension DependencyValues {
    var aria2Repository: any Aria2Repository {
        get { self[Aria2RepositoryKey.self] }
        set { self[Aria2RepositoryKey.self] = newValue }
    }
}

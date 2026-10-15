import Alamofire
import Combine
import Dependencies
import Foundation

struct Aria2RepositoryImpl: Aria2Repository {
    @Dependency(\.session) private var session

    func call<D: Decodable & Sendable>(data: some Encodable & Sendable) -> AnyPublisher<Aria2Response<D>, Error> {
        session.request(Aria2Service.call(data: data))
            .publishDecodable(type: Aria2Response<D>.self)
            .value()
            .tryMap { $0 }
            .eraseToAnyPublisher()
    }

    func multicall<D: Decodable & Sendable>(data: [some Encodable & Sendable]) -> AnyPublisher<[Aria2Response<D>], Error> {
        session.request(Aria2Service.multicall(data: data))
            .publishDecodable(type: [Aria2Response<D>].self)
            .value()
            .tryMap { $0 }
            .eraseToAnyPublisher()
    }
}

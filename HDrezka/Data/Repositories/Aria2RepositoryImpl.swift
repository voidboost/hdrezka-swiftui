import Alamofire
import Combine
import FactoryKit
import Foundation

struct Aria2RepositoryImpl: Aria2Repository {
    @Injected(\.session) private var session

    func call<D: Decodable>(data: some Encodable) -> AnyPublisher<Aria2Response<D>, Error> {
        session.request(Aria2Service.call(data: data))
            .publishDecodable(type: Aria2Response<D>.self)
            .value()
            .tryMap { $0 }
            .eraseToAnyPublisher()
    }

    func multicall<D: Decodable>(data: [some Encodable]) -> AnyPublisher<[Aria2Response<D>], Error> {
        session.request(Aria2Service.multicall(data: data))
            .publishDecodable(type: [Aria2Response<D>].self)
            .value()
            .tryMap { $0 }
            .eraseToAnyPublisher()
    }
}

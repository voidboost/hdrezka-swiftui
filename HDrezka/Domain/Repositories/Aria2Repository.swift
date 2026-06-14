import Combine

protocol Aria2Repository {
    func call<D: Decodable>(data: some Encodable) -> AnyPublisher<Aria2Response<D>, Error>

    func multicall<D: Decodable>(data: [some Encodable]) -> AnyPublisher<[Aria2Response<D>], Error>
}

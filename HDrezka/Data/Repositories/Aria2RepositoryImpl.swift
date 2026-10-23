import Alamofire
import Dependencies
import Foundation

struct Aria2RepositoryImpl: Aria2Repository {
    @Dependency(\.session) private var session

    func call<D: Decodable & Sendable>(data: some Encodable & Sendable) async throws -> Aria2Response<D> {
        try await session.request(Aria2Service.call(data: data))
            .serializingDecodable(Aria2Response<D>.self)
            .value
    }

    func multicall<D: Decodable & Sendable>(data: [some Encodable & Sendable]) async throws -> [Aria2Response<D>] {
        try await session.request(Aria2Service.multicall(data: data))
            .serializingDecodable([Aria2Response<D>].self)
            .value
    }
}

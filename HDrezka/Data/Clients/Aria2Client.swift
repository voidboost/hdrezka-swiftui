import Alamofire
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct Aria2Client: Sendable {
    var send: @Sendable (_ body: Data) async throws -> Data
}

extension Aria2Client {
    func call<D: Decodable & Sendable>(data: some Encodable & Sendable) async throws -> Aria2Response<D> {
        try await JSONDecoder().decode(Aria2Response<D>.self, from: send(body: JSONEncoder().encode(data)))
    }

    func multicall<D: Decodable & Sendable>(data: [some Encodable & Sendable]) async throws -> [Aria2Response<D>] {
        try await JSONDecoder().decode([Aria2Response<D>].self, from: send(body: JSONEncoder().encode(data)))
    }
}

extension Aria2Client: DependencyKey {
    static let liveValue: Self = {
        @Dependency(\.session) var session

        return Self(
            send: { body in
                try await session.request(Aria2Service(body: body))
                    .serializingData()
                    .value
            }
        )
    }()

    static let testValue = Self()
}

extension DependencyValues {
    var aria2Client: Aria2Client {
        get { self[Aria2Client.self] }
        set { self[Aria2Client.self] = newValue }
    }
}

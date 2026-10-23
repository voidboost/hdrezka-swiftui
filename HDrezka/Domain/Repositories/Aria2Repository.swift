import Dependencies

protocol Aria2Repository: Sendable {
    func call<D: Decodable & Sendable>(data: some Encodable & Sendable) async throws -> Aria2Response<D>

    func multicall<D: Decodable & Sendable>(data: [some Encodable & Sendable]) async throws -> [Aria2Response<D>]
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

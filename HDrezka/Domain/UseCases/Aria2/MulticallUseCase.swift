import Combine

struct MulticallUseCase {
    private let repository: Aria2Repository

    init(repository: Aria2Repository) {
        self.repository = repository
    }

    func callAsFunction<D: Decodable>(data: [some Encodable]) -> AnyPublisher<[Aria2Response<D>], Error> {
        repository.multicall(data: data)
    }
}

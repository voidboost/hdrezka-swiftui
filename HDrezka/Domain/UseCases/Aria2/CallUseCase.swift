import Combine

struct CallUseCase {
    private let repository: Aria2Repository

    init(repository: Aria2Repository) {
        self.repository = repository
    }

    func callAsFunction<D: Decodable>(data: some Encodable) -> AnyPublisher<Aria2Response<D>, Error> {
        repository.call(data: data)
    }
}

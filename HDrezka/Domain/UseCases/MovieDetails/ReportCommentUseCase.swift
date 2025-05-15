import Combine

struct ReportCommentUseCase {
    private let repository: MovieDetailsRepository

    init(repository: MovieDetailsRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String, issue: Int, text: String) -> AnyPublisher<Bool, Error> {
        repository.reportComment(id: id, issue: issue, text: text)
    }
}

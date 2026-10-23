import Dependencies

struct ReportCommentUseCase {
    @Dependency(\.movieDetailsRepository) private var repository

    func callAsFunction(id: String, issue: Int, text: String) async throws -> Bool {
        try await repository.reportComment(id: id, issue: issue, text: text)
    }
}

extension ReportCommentUseCase: DependencyKey {
    static let liveValue = Self()
}

extension DependencyValues {
    var reportCommentUseCase: ReportCommentUseCase {
        get { self[ReportCommentUseCase.self] }
        set { self[ReportCommentUseCase.self] = newValue }
    }
}

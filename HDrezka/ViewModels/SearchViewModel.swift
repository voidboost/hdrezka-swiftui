import Combine
import FactoryKit
import SwiftUI

@Observable
class SearchViewModel {
    @ObservationIgnored @LazyInjected(\.searchUseCase) private var searchUseCase

    private(set) var state: DataState<[MovieSimple]> = .data([])
    private(set) var paginationState: DataPaginationState = .idle

    private(set) var title: String = .init(localized: "key.search")

    @ObservationIgnored private var searchTask: Task<Void, Never>?

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    @ObservationIgnored private var page = 1

    var query: String = ""

    private func getData(query: String, isInitial: Bool = true) {
        searchUseCase(query: query, page: page)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self,
                      case let .failure(error) = completion
                else {
                    return
                }

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.state = .error(error)
                    } else {
                        self.paginationState = .error(error)
                    }
                }
            } receiveValue: { [weak self] result in
                guard let self else { return }

                self.page += 1

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.state = .data(result)
                    } else {
                        if !result.isEmpty {
                            self.state.append(result)
                            self.paginationState = .idle
                        } else {
                            self.paginationState = .error(HDrezkaError.unknown)
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func load(force: Bool = false) {
        searchTask?.cancel()

        searchTask = Task { @MainActor [weak self] in
            if !force {
                try? await Task.sleep(for: .milliseconds(500))
            }

            guard !Task.isCancelled, let self else { return }

            self.paginationState = .idle
            self.page = 1
            self.subscriptions.flush()

            if !self.query.trim().isEmpty {
                withAnimation(.easeInOut) {
                    self.state = .loading
                    self.title = .init(localized: "key.search.result-\(self.query.trim())")
                }

                self.getData(query: self.query.trim())
            } else {
                withAnimation(.easeInOut) {
                    self.title = .init(localized: "key.search")
                    self.state = .data([])
                }
            }
        }
    }

    func loadMore() {
        guard paginationState == .idle, !query.isEmpty else { return }

        withAnimation(.easeInOut) {
            self.paginationState = .loading
        }

        getData(query: query.trim(), isInitial: false)
    }
}

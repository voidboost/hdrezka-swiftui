import Combine
import FactoryKit
import SwiftUI

@Observable
class SearchViewModel {
    @ObservationIgnored @LazyInjected(\.searchUseCase) private var searchUseCase

    private(set) var state: DataState<[MovieSimple]> = .data([])
    private(set) var paginationState: DataPaginationState = .idle

    private(set) var title: String = .init(localized: "key.search")

    @ObservationIgnored private var searchWork: DispatchWorkItem?

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    @ObservationIgnored private var page = 1

    var query: String = ""

    private func getData(query: String, isInitial: Bool = true) {
        searchUseCase(query: query, page: page)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.state = .error(error)
                    } else {
                        self.paginationState = .error(error)
                    }
                }
            } receiveValue: { result in
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
        searchWork?.cancel()

        if force {
            paginationState = .idle
            page = 1
            subscriptions.flush()

            if !query.trim().isEmpty {
                withAnimation(.easeInOut) {
                    state = .loading
                    title = .init(localized: "key.search.result-\(query.trim())")
                }

                getData(query: query.trim())
            } else {
                withAnimation(.easeInOut) {
                    title = .init(localized: "key.search")
                    state = .data([])
                }
            }
        } else {
            searchWork = DispatchWorkItem {
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

            if let searchWork {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: searchWork)
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

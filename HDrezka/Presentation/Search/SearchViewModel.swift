import Combine
import FactoryKit
import SwiftUI

@Observable
class SearchViewModel {
    @ObservationIgnored @LazyInjected(\.searchUseCase) private var searchUseCase

    private(set) var state: DataState<[MovieSimple]> = .loading
    private(set) var paginationState: DataPaginationState = .idle

    private(set) var title: String = .init(localized: "key.search")

    @ObservationIgnored private var searchWork: DispatchWorkItem?

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    @ObservationIgnored private var page = 1

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

    func load(query: String) {
        searchWork?.cancel()

        searchWork = DispatchWorkItem {
            self.paginationState = .idle
            self.page = 1
            self.subscriptions.flush()

            if !query.isEmpty {
                self.state = .loading
                self.title = .init(localized: "key.search.result-\(query)")

                self.getData(query: query)
            } else {
                self.title = .init(localized: "key.search")
                self.state = .data([])
            }
        }

        if let searchWork {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: searchWork)
        }
    }

    func loadMore(query: String) {
        guard paginationState == .idle, !query.isEmpty else { return }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        getData(query: query, isInitial: false)
    }
}

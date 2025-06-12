import Combine
import FactoryKit
import SwiftUI

class SearchViewModel: ObservableObject {
    @Injected(\.searchUseCase) private var searchUseCase

    @Published private(set) var state: DataState<[MovieSimple]> = .loading
    @Published private(set) var paginationState: DataPaginationState = .idle

    @Published private(set) var title: String = .init(localized: "key.search")

    private var searchWork: DispatchWorkItem?

    private var subscriptions: Set<AnyCancellable> = []

    private var page = 1

    private func getData(query: String, isInitial: Bool = true) {
        searchUseCase(query: query, page: page)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.state = .error(error as NSError)
                    } else {
                        self.paginationState = .error(error as NSError)
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
                            self.paginationState = .error(HDrezkaError.unknown as NSError)
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
            self.subscriptions.forEach { $0.cancel() }
            self.subscriptions.removeAll()

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

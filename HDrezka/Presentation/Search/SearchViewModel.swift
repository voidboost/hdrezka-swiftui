import Combine
import FactoryKit
import SwiftUI

class SearchViewModel: ObservableObject {
    @Injected(\.searchUseCase) private var searchUseCase

    @Published var state: DataState<[MovieSimple]> = .loading
    @Published var paginationState: DataPaginationState = .idle

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
                            self.paginationState = .error(NSError())
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func load(query: String) {
        paginationState = .idle
        page = 1

        if !query.isEmpty {
            state = .loading
            subscriptions.forEach { $0.cancel() }
            subscriptions.removeAll()

            getData(query: query)
        } else {
            state = .data([])
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

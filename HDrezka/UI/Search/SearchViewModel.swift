import Combine
import Factory
import SwiftUI

@Observable
class SearchViewModel {
    @ObservationIgnored
    @Injected(\.search)
    private var search

    var state: DataState<[MovieSimple]> = .loading
    var paginationState: DataPaginationState = .idle

    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []

    @ObservationIgnored
    private var page = 1

    private func getMovies(query: String) {
        paginationState = .idle
        page = 1

        if !query.isEmpty {
            state = .loading

            subscriptions.forEach { $0.cancel() }
            subscriptions.removeAll()

            search
                .search(query: query, page: page)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.state = .error(error as NSError)
                    }
                } receiveValue: { result in
                    self.page += 1

                    withAnimation(.easeInOut) {
                        self.state = .data(result)
                    }
                }
                .store(in: &subscriptions)
        } else {
            state = .data([])
        }
    }

    private func loadMore(query: String) {
        guard paginationState == .idle, !query.isEmpty else {
            return
        }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        search
            .search(query: query, page: page)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.paginationState = .error(error as NSError)
                }
            } receiveValue: { result in
                if !result.isEmpty {
                    withAnimation(.easeInOut) {
                        self.state.append(result)
                        self.paginationState = .idle
                    }
                    self.page += 1
                } else {
                    withAnimation(.easeInOut) {
                        self.paginationState = .error(NSError())
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func reload(query: String) {
        getMovies(query: query)
    }

    func nextPage(query: String) {
        loadMore(query: query)
    }
}

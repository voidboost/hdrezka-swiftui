import Combine
import FactoryKit
import SwiftUI

@Observable
class CollectionsViewModel {
    @ObservationIgnored
    @Injected(\.collections)
    private var collectionsRepository

    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []

    var state: DataState<[MoviesCollection]> = .loading
    var paginationState: DataPaginationState = .idle

    @ObservationIgnored
    private var page = 1

    private func getCollection() {
        collectionsRepository
            .getCollections(page: page)
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
    }

    func nextPage() {
        guard paginationState == .idle else {
            return
        }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        collectionsRepository
            .getCollections(page: page)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.paginationState = .error(error as NSError)
                }
            } receiveValue: { result in
                self.page += 1

                withAnimation(.easeInOut) {
                    self.state.append(result)
                    self.paginationState = .idle
                }
            }
            .store(in: &subscriptions)
    }

    func reload() {
        state = .loading
        paginationState = .idle
        page = 1
        getCollection()
    }
}

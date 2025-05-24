import Combine
import FactoryKit
import SwiftUI

class CollectionsViewModel: ObservableObject {
    @Injected(\.getCollectionsUseCase) private var getCollectionsUseCase

    private var subscriptions: Set<AnyCancellable> = []

    @Published var state: DataState<[MoviesCollection]> = .loading
    @Published var paginationState: DataPaginationState = .idle

    private var page = 1

    private func getCollection() {
        getCollectionsUseCase(page: page)
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

        getCollectionsUseCase(page: page)
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

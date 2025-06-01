import Combine
import FactoryKit
import SwiftUI

class CollectionsViewModel: ObservableObject {
    @Injected(\.getCollectionsUseCase) private var getCollectionsUseCase

    private var subscriptions: Set<AnyCancellable> = []

    @Published private(set) var state: DataState<[MoviesCollection]> = .loading
    @Published private(set) var paginationState: DataPaginationState = .idle

    private var page = 1

    private func getData(isInitial: Bool = true) {
        getCollectionsUseCase(page: page)
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
                        self.state.append(result)
                        self.paginationState = .idle
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func load() {
        state = .loading
        paginationState = .idle
        page = 1

        getData()
    }

    func loadMore() {
        guard paginationState == .idle else { return }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        getData(isInitial: false)
    }
}

import Combine
import FactoryKit
import SwiftUI

class WatchingLaterViewModel: ObservableObject {
    @Injected(\.getWatchingLaterMoviesUseCase) private var getWatchingLaterMoviesUseCase

    private var subscriptions: Set<AnyCancellable> = []

    @Published var state: DataState<[MovieWatchLater]> = .loading

    func getMovies() {
        state = .loading

        getWatchingLaterMoviesUseCase()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.state = .error(error as NSError)
                }
            } receiveValue: { result in
                withAnimation(.easeInOut) {
                    self.state = .data(result)
                }
            }
            .store(in: &subscriptions)
    }
}

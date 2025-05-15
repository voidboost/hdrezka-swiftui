import Combine
import FactoryKit
import SwiftUI

@Observable
class WatchingLaterViewModel {
    @ObservationIgnored
    @Injected(\.account)
    private var account

    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []

    var state: DataState<[MovieWatchLater]> = .loading

    private func getMovies() {
        account
            .getWatchingLaterMovies()
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

    func reload() {
        state = .loading
        getMovies()
    }
}

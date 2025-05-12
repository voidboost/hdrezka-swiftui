import Combine
import Factory
import SwiftUI

@Observable
class CategoriesViewModel {
    @ObservationIgnored
    @Injected(\.search)
    private var search

    var selection: UUID?
    var state: DataState<[MovieType]> = .loading

    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []

    private func getTypes() {
        search
            .categories()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.state = .error(error as NSError)
                }
            } receiveValue: { types in
                withAnimation(.easeInOut) {
                    self.selection = types.first?.id
                    self.state = .data(types)
                }
            }
            .store(in: &subscriptions)
    }

    func reload() {
        state = .loading
        getTypes()
    }
}

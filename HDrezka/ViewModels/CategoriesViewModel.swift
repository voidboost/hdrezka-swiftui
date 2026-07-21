import Combine
import FactoryKit
import SwiftUI

@Observable
class CategoriesViewModel {
    @ObservationIgnored @LazyInjected(\.categoriesUseCase) private var categoriesUseCase

    private(set) var state: DataState<[MovieType]> = .loading

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    func load() {
        state = .loading

        categoriesUseCase()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self,
                      case let .failure(error) = completion
                else {
                    return
                }

                withAnimation(.easeInOut) {
                    self.state = .error(error)
                }
            } receiveValue: { [weak self] types in
                guard let self else { return }

                withAnimation(.easeInOut) {
                    self.state = .data(types)
                }
            }
            .store(in: &subscriptions)
    }
}

import Combine
import FactoryKit
import SwiftUI

class CategoriesViewModel: ObservableObject {
    @Injected(\.categoriesUseCase) private var categoriesUseCase

    @Published private(set) var state: DataState<[MovieType]> = .loading

    private var subscriptions: Set<AnyCancellable> = []

    func getTypes() {
        state = .loading

        categoriesUseCase()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.state = .error(error as NSError)
                }
            } receiveValue: { types in
                withAnimation(.easeInOut) {
                    self.state = .data(types)
                }
            }
            .store(in: &subscriptions)
    }
}

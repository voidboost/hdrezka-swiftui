import Combine
import FactoryKit
import SwiftUI

class PersonViewModel: ObservableObject {
    @Injected(\.getPersonDetailsUseCase) private var getPersonDetailsUseCase

    @Published var state: DataState<PersonDetailed> = .loading

    private var subscriptions: Set<AnyCancellable> = []

    func getDetails(id: String) {
        state = .loading

        getPersonDetailsUseCase(id: id)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.state = .error(error as NSError)
                }
            } receiveValue: { detail in
                withAnimation(.easeInOut) {
                    self.state = .data(detail)
                }
            }
            .store(in: &subscriptions)
    }
}

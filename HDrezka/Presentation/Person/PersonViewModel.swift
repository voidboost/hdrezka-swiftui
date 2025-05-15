import Combine
import FactoryKit
import SwiftUI

@Observable
class PersonViewModel {
    @ObservationIgnored
    @Injected(\.getPersonDetailsUseCase)
    private var getPersonDetailsUseCase

    var state: DataState<PersonDetailed> = .loading

    @ObservationIgnored
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

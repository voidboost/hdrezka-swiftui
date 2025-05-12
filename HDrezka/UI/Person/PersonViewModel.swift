import Combine
import Factory
import SwiftUI

@Observable
class PersonViewModel {
    @ObservationIgnored
    @Injected(\.people)
    private var people

    var state: DataState<PersonDetailed> = .loading

    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []

    func getDetails(id: String) {
        state = .loading

        people
            .getPersonDetails(id: id)
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

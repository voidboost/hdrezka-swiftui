import Combine
import FactoryKit
import SwiftUI

@Observable
class PersonViewModel {
    @ObservationIgnored @LazyInjected(\.getPersonDetailsUseCase) private var getPersonDetailsUseCase

    @ObservationIgnored let id: String

    init(id: String) {
        self.id = id
    }

    private(set) var state: DataState<PersonDetailed> = .loading

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    func load() {
        state = .loading

        getPersonDetailsUseCase(id: id)
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
            } receiveValue: { [weak self] detail in
                guard let self else { return }

                withAnimation(.easeInOut) {
                    self.state = .data(detail)
                }
            }
            .store(in: &subscriptions)
    }
}

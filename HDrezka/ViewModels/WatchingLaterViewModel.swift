import Combine
import FactoryKit
import SwiftUI

@Observable
class WatchingLaterViewModel {
    @ObservationIgnored @LazyInjected(\.getWatchingLaterMoviesUseCase) private var getWatchingLaterMoviesUseCase
    @ObservationIgnored @LazyInjected(\.switchWatchedItemUseCase) private var switchWatchedItemUseCase
    @ObservationIgnored @LazyInjected(\.removeWatchingItemUseCase) private var removeWatchingItemUseCase

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    private(set) var state: DataState<[MovieWatchLater]> = .loading

    private(set) var error: Error?
    var isErrorPresented: Bool = false

    func load() {
        state = .loading

        getWatchingLaterMoviesUseCase()
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
            } receiveValue: { [weak self] result in
                guard let self else { return }

                withAnimation(.easeInOut) {
                    self.state = .data(result)
                }
            }
            .store(in: &subscriptions)
    }

    func switchWatchedItem(movie: MovieWatchLater) {
        switchWatchedItemUseCase(item: movie)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self,
                      case let .failure(error) = completion
                else {
                    return
                }

                self.error = error
                self.isErrorPresented = true
            } receiveValue: { [weak self] result in
                guard let self else { return }

                if result, var movies = self.state.data {
                    if let index = movies.firstIndex(of: movie) {
                        movies[index].watched.toggle()

                        if !movie.watched {
                            movies.move(
                                fromOffsets: IndexSet(integer: index),
                                toOffset: movies.count
                            )
                        }

                        withAnimation(.easeInOut) {
                            self.state = .data(movies)
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func removeWatchingItem(movie: MovieWatchLater) {
        removeWatchingItemUseCase(item: movie)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self,
                      case let .failure(error) = completion
                else {
                    return
                }

                self.error = error
                self.isErrorPresented = true
            } receiveValue: { [weak self] delete in
                guard let self else { return }

                if delete, var movies = self.state.data {
                    movies.removeAll(where: {
                        $0.id == movie.id
                    })

                    withAnimation(.easeInOut) {
                        self.state = .data(movies)
                    }
                }
            }
            .store(in: &subscriptions)
    }
}

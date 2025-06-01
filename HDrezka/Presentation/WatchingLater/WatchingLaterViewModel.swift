import Combine
import FactoryKit
import SwiftUI

class WatchingLaterViewModel: ObservableObject {
    @Injected(\.getWatchingLaterMoviesUseCase) private var getWatchingLaterMoviesUseCase
    @Injected(\.switchWatchedItemUseCase) private var switchWatchedItemUseCase
    @Injected(\.removeWatchingItemUseCase) private var removeWatchingItemUseCase

    private var subscriptions: Set<AnyCancellable> = []

    @Published private(set) var state: DataState<[MovieWatchLater]> = .loading
 
    @Published private(set) var error: Error?
    @Published var isErrorPresented: Bool = false

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

    func switchWatchedItem(movie: MovieWatchLater) {
        switchWatchedItemUseCase(item: movie)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                self.error = error
                self.isErrorPresented = true
            } receiveValue: { result in
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
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                self.error = error
                self.isErrorPresented = true
            } receiveValue: { delete in
                if delete, var movies = self.state.data {
                    movies.removeAll(where: {
                        $0.id == movie.id
                    })

                    withAnimation(.easeInOut) {
                        self.state = .data(movies)
                    }

                    try? PersistenceController.shared.viewContext.fetch(PlayerPosition.fetch())
                        .filter { $0.id == movie.watchLaterId.id }
                        .forEach(PersistenceController.shared.viewContext.delete)

                    PersistenceController.shared.viewContext.saveContext()
                }
            }
            .store(in: &subscriptions)
    }
}

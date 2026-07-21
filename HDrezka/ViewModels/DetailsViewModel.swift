import Combine
import FactoryKit
import SwiftUI
import YouTubePlayerKit

@Observable
class DetailsViewModel {
    @ObservationIgnored @LazyInjected(\.getMovieDetailsUseCase) private var getMovieDetailsUseCase
    @ObservationIgnored @LazyInjected(\.getMovieTrailerIdUseCase) private var getMovieTrailerIdUseCase
    @ObservationIgnored @LazyInjected(\.rateUseCase) private var rateUseCase

    @ObservationIgnored let id: String

    init(id: String) {
        self.id = id
    }

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    private(set) var state: DataState<MovieDetailed> = .loading
    private(set) var trailerId: String?

    var countryDestination: MovieCountry?
    var genreDestination: MovieGenre?
    var personDestination: PersonSimple?
    var listDestination: MovieList?
    var collectionDestination: MoviesCollection?

    func load() {
        state = .loading

        getMovieDetailsUseCase(movieId: id)
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
                } completion: { [weak self] in
                    guard let self,
                          let movieId = detail.movieId.id
                    else {
                        return
                    }

                    self.getMovieTrailerIdUseCase(movieId: movieId)
                        .receive(on: DispatchQueue.main)
                        .sink { _ in } receiveValue: { [weak self] trailerId in
                            guard let self else { return }

                            withAnimation(.easeInOut) {
                                self.trailerId = trailerId
                            }
                        }
                        .store(in: &self.subscriptions)
                }
            }
            .store(in: &subscriptions)
    }

    var isErrorPresented: Bool = false
    var error: Error?

    func rate(rating: Int) {
        if let id = id.id {
            rateUseCase(id: id, rating: rating)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self,
                          case let .failure(error) = completion
                    else {
                        return
                    }

                    self.error = error
                    self.isErrorPresented = true
                } receiveValue: { [weak self] rating in
                    guard let self else { return }

                    if let rating, case var .data(details) = self.state {
                        details.rate(rating.0, rating.1)

                        withAnimation(.easeInOut) {
                            self.state = .data(details)
                        }
                    } else {
                        self.isErrorPresented = true
                    }
                }
                .store(in: &subscriptions)
        }
    }
}

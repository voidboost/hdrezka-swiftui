import Combine
import Factory
import SwiftUI
import YouTubePlayerKit

@Observable
class DetailsViewModel {
    @ObservationIgnored
    @Injected(\.movieDetails)
    private var movieDetails

    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = []

    var state: DataState<MovieDetailed> = .loading
    var trailer: YouTubePlayer?

    func getDetails(id: String) {
        state = .loading

        movieDetails
            .getMovieDetails(movieId: id)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.state = .error(error as NSError)
                }
            } receiveValue: { detail in
                withAnimation(.easeInOut) {
                    self.state = .data(detail)
                } completion: {
                    if let movieId = detail.movieId.id {
                        self.movieDetails
                            .getMovieTrailerId(movieId: movieId)
                            .receive(on: DispatchQueue.main)
                            .sink { _ in } receiveValue: { trailerId in
                                #if DEBUG
                                    let isLoggingEnabled = true
                                #else
                                    let isLoggingEnabled = false
                                #endif

                                withAnimation(.easeInOut) {
                                    self.trailer = YouTubePlayer(
                                        source: .video(id: trailerId),
                                        parameters: .init(
                                            autoPlay: false,
                                            loopEnabled: true,
                                            showControls: true,
                                            showFullscreenButton: true
                                        ),
                                        configuration: .init(
                                            openURLAction: .init { url, _ in
                                                NSWorkspace.shared.open(url)
                                            }
                                        ),
                                        isLoggingEnabled: isLoggingEnabled
                                    )
                                }
                            }
                            .store(in: &self.subscriptions)
                    }
                }
            }
            .store(in: &subscriptions)
    }

    var isErrorPresented: Bool = false
    var error: Error?

    func rate(id: String, rating: Int) {
        movieDetails
            .rate(id: id, rating: rating)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                self.error = error
                self.isErrorPresented = true
            } receiveValue: { rating in
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

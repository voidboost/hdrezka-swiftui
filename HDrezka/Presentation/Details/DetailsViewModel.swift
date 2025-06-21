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
    private(set) var trailer: YouTubePlayer?

    func load() {
        state = .loading

        getMovieDetailsUseCase(movieId: id)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.state = .error(error)
                }
            } receiveValue: { detail in
                withAnimation(.easeInOut) {
                    self.state = .data(detail)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if let movieId = detail.movieId.id {
                        self.getMovieTrailerIdUseCase(movieId: movieId)
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
                                            showFullscreenButton: true,
                                        ),
                                        configuration: .init(
                                            openURLAction: .init { url, _ in
                                                NSWorkspace.shared.open(url)
                                            },
                                        ),
                                        isLoggingEnabled: isLoggingEnabled,
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

    func rate(rating: Int) {
        if let id = id.id {
            rateUseCase(id: id, rating: rating)
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
}

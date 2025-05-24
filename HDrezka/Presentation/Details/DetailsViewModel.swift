import Combine
import FactoryKit
import SwiftUI
import YouTubePlayerKit

class DetailsViewModel: ObservableObject {
    @Injected(\.getMovieDetailsUseCase) private var getMovieDetailsUseCase
    @Injected(\.getMovieTrailerIdUseCase) private var getMovieTrailerIdUseCase
    @Injected(\.rateUseCase) private var rateUseCase

    private var subscriptions: Set<AnyCancellable> = []

    @Published var state: DataState<MovieDetailed> = .loading
    @Published var trailer: YouTubePlayer?

    func getDetails(id: String) {
        state = .loading

        getMovieDetailsUseCase(movieId: id)
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

    @Published var isErrorPresented: Bool = false
    @Published var error: Error?

    func rate(id: String, rating: Int) {
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

import Combine
import Dependencies
import SwiftUI

@Observable
class HomeViewModel {
    @ObservationIgnored @Dependency(\.getHotMoviesUseCase) private var getHotMoviesUseCase
//    @ObservationIgnored @Dependency(\.getFeaturedMoviesUseCase) private var getFeaturedMoviesUseCase
    @ObservationIgnored @Dependency(\.getWatchingNowMoviesUseCase) private var getWatchingNowMoviesUseCase
    @ObservationIgnored @Dependency(\.getLatestMoviesUseCase) private var getLatestMoviesUseCase
    @ObservationIgnored @Dependency(\.getLatestNewestMoviesUseCase) private var getLatestNewestMoviesUseCase
    @ObservationIgnored @Dependency(\.getPopularMoviesUseCase) private var getPopularMoviesUseCase
    @ObservationIgnored @Dependency(\.getSoonMoviesUseCase) private var getSoonMoviesUseCase

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    private(set) var state: DataState<[Category]> = .loading
    private(set) var paginationState: DataPaginationState = .idle

    var isSeriesUpdatesPresented: Bool = false

    @ObservationIgnored private var page: Categories?

    private func getData(category: Categories, isInitial: Bool = true) {
        getPublisher(category: category)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self,
                      case let .failure(error) = completion
                else {
                    return
                }

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.state = .error(error)
                    } else {
                        self.paginationState = .error(error)
                    }
                }
            } receiveValue: { [weak self] movies in
                guard let self else { return }

                self.page = Categories.allCases.element(after: category)
                let newCategory = Category(category: category, title: category.localized, movies: movies)

                withAnimation(.easeInOut) {
                    if isInitial {
                        self.state = .data([newCategory])
                    } else {
                        self.state.append([newCategory])
                        self.paginationState = .idle
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func getPublisher(category: Categories) -> AnyPublisher<[MovieSimple], Error> {
        switch category {
        case .hot: getHotMoviesUseCase(genre: 0)
//            case .featured: getFeaturedMoviesUseCase(page: 1, genre: 0)
        case .watchingNow: getWatchingNowMoviesUseCase(page: 1, genre: 0)
        case .latest: getLatestMoviesUseCase(page: 1, genre: 0)
        case .newest: getLatestNewestMoviesUseCase(page: 1, genre: 0)
        case .popular: getPopularMoviesUseCase(page: 1, genre: 0)
        case .soon: getSoonMoviesUseCase(page: 1, genre: 0)
        }
    }

    func load() {
        state = .loading
        paginationState = .idle

        page = Categories.allCases.first

        if let page {
            getData(category: page)
        }
    }

    func loadMore(reset: Bool = false) {
        guard let page, paginationState == .idle || reset else { return }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        getData(category: page, isInitial: false)
    }
}

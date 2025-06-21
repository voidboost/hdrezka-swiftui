import Combine
import FactoryKit
import SwiftUI

@Observable
class HomeViewModel {
    @ObservationIgnored @LazyInjected(\.getHotMoviesUseCase) private var getHotMoviesUseCase
//    @ObservationIgnored @LazyInjected(\.getFeaturedMoviesUseCase) private var getFeaturedMoviesUseCase
    @ObservationIgnored @LazyInjected(\.getWatchingNowMoviesUseCase) private var getWatchingNowMoviesUseCase
    @ObservationIgnored @LazyInjected(\.getLatestMoviesUseCase) private var getLatestMoviesUseCase
    @ObservationIgnored @LazyInjected(\.getLatestNewestMoviesUseCase) private var getLatestNewestMoviesUseCase
    @ObservationIgnored @LazyInjected(\.getPopularMoviesUseCase) private var getPopularMoviesUseCase
    @ObservationIgnored @LazyInjected(\.getSoonMoviesUseCase) private var getSoonMoviesUseCase

    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    private(set) var state: DataState<[Category]> = .loading
    private(set) var paginationState: DataPaginationState = .idle

    var isSeriesUpdatesPresented: Bool = false

    @ObservationIgnored private var page: Categories?

    private func getData(category: Categories, isInitial: Bool = true) {
        getPublisher(category: category)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    withAnimation(.easeInOut) {
                        if isInitial {
                            self.state = .error(error)
                        } else {
                            self.paginationState = .error(error)
                        }
                    }
                }
            } receiveValue: { movies in
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

struct Category: Identifiable, Hashable {
    let category: Categories
    let title: String
    let movies: [MovieSimple]
    let id: UUID

    init(category: Categories, title: String, movies: [MovieSimple], id: UUID = .init()) {
        self.category = category
        self.title = title
        self.movies = movies
        self.id = id
    }
}

enum Categories: LocalizedStringKey, CaseIterable, Hashable {
    case hot = "key.filters.hot"
//    case featured = "key.filters.featured"
    case watchingNow = "key.filters.watching_now"
    case newest = "key.filters.newest"
    case latest = "key.filters.latest"
    case popular = "key.filters.popular"
    case soon = "key.filters.soon"

    var localized: String {
        rawValue.toString() ?? ""
    }
}

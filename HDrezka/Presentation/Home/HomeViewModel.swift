import Combine
import FactoryKit
import SwiftUI

class HomeViewModel: ObservableObject {
    @Injected(\.getHotMoviesUseCase) private var getHotMoviesUseCase
//    @Injected(\.getFeaturedMoviesUseCase) private var getFeaturedMoviesUseCase
    @Injected(\.getWatchingNowMoviesUseCase) private var getWatchingNowMoviesUseCase
    @Injected(\.getLatestMoviesUseCase) private var getLatestMoviesUseCase
    @Injected(\.getLatestNewestMoviesUseCase) private var getLatestNewestMoviesUseCase
    @Injected(\.getPopularMoviesUseCase) private var getPopularMoviesUseCase
    @Injected(\.getSoonMoviesUseCase) private var getSoonMoviesUseCase

    private var subscriptions: Set<AnyCancellable> = []

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

    @Published private(set) var state: DataState<[Category]> = .loading
    @Published private(set) var paginationState: DataPaginationState = .idle

    @Published var isSeriesUpdatesPresented: Bool = false

    private var page: Categories?

    private func getData(category: Categories, isInitial: Bool = true) {
        getPublisher(category: category)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    withAnimation(.easeInOut) {
                        if isInitial {
                            self.state = .error(error as NSError)
                        } else {
                            self.paginationState = .error(error as NSError)
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

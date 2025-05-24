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

    @Published var state: DataState<[Category]> = .loading
    @Published var paginationState: DataPaginationState = .idle

    private var page: Categories? = Categories.allCases.first ?? .hot

    private func getMovies() {
        state = .loading
        paginationState = .idle
        page = Categories.allCases.first ?? .watchingNow

        if let page {
            let publisher = switch page {
            case .hot:
                getHotMoviesUseCase(genre: 0)
//            case .featured:
//                getFeaturedMoviesUseCase(page: 1, genre: 0)
            case .watchingNow:
                getWatchingNowMoviesUseCase(page: 1, genre: 0)
            case .latest:
                getLatestMoviesUseCase(page: 1, genre: 0)
            case .newest:
                getLatestNewestMoviesUseCase(page: 1, genre: 0)
            case .popular:
                getPopularMoviesUseCase(page: 1, genre: 0)
            case .soon:
                getSoonMoviesUseCase(page: 1, genre: 0)
            }

            publisher
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    withAnimation(.easeInOut) {
                        self.state = .error(error as NSError)
                    }
                } receiveValue: { movies in
                    self.page = Categories.allCases.element(after: page)

                    withAnimation(.easeInOut) {
                        self.state = .data([.init(category: page, title: page.localized, movies: movies)])
                    }
                }
                .store(in: &subscriptions)
        }
    }

    private func loadMore() {
        guard let page, paginationState == .idle else {
            return
        }

        withAnimation(.easeInOut) {
            paginationState = .loading
        }

        let publisher = switch page {
        case .hot:
            getHotMoviesUseCase(genre: 0)
//        case .featured:
//            getFeaturedMoviesUseCase(page: 1, genre: 0)
        case .watchingNow:
            getWatchingNowMoviesUseCase(page: 1, genre: 0)
        case .latest:
            getLatestMoviesUseCase(page: 1, genre: 0)
        case .newest:
            getLatestNewestMoviesUseCase(page: 1, genre: 0)
        case .popular:
            getPopularMoviesUseCase(page: 1, genre: 0)
        case .soon:
            getSoonMoviesUseCase(page: 1, genre: 0)
        }

        publisher
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    self.paginationState = .error(error as NSError)
                }
            } receiveValue: { movies in
                self.page = Categories.allCases.element(after: page)

                withAnimation(.easeInOut) {
                    self.state.append([.init(category: page, title: page.localized, movies: movies)])
                    self.paginationState = .idle
                }
            }
            .store(in: &subscriptions)
    }

    func reload() {
        getMovies()
    }

    func nextCategory() {
        loadMore()
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

import Combine
import FactoryKit
import SwiftUI

@Observable
class HomeViewModel {
    @ObservationIgnored
    @Injected(\.getHotMoviesUseCase)
    private var getHotMoviesUseCase
//    @ObservationIgnored
//    @Injected(\.getFeaturedMoviesUseCase)
//    private var getFeaturedMoviesUseCase
    @ObservationIgnored
    @Injected(\.getWatchingNowMoviesUseCase)
    private var getWatchingNowMoviesUseCase
    @ObservationIgnored
    @Injected(\.getLatestMoviesUseCase)
    private var getLatestMoviesUseCase
    @ObservationIgnored
    @Injected(\.getLatestNewestMoviesUseCase)
    private var getLatestNewestMoviesUseCase
    @ObservationIgnored
    @Injected(\.getPopularMoviesUseCase)
    private var getPopularMoviesUseCase
    @ObservationIgnored
    @Injected(\.getSoonMoviesUseCase)
    private var getSoonMoviesUseCase

    @ObservationIgnored
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

    var state: DataState<[Category]> = .loading
    var paginationState: DataPaginationState = .idle

    @ObservationIgnored
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

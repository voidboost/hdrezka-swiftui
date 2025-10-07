import Defaults
import SwiftUI

struct ListView: View {
    @State private var viewModel: ListViewModel

    init(movies: [MovieSimple], title: String) {
        viewModel = ListViewModel(movies: movies, title: title)
    }

    init(list: MovieList) {
        viewModel = ListViewModel(list: list)
    }

    init(country: MovieCountry) {
        viewModel = ListViewModel(country: country)
    }

    init(genre: MovieGenre) {
        viewModel = ListViewModel(genre: genre)
    }

    init(category: Categories) {
        viewModel = ListViewModel(category: category)
    }

    init(collection: MoviesCollection) {
        viewModel = ListViewModel(collection: collection)
    }

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading)]

    @Default(.isLoggedIn) private var isLoggedIn

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                if let movies = viewModel.state.data, !movies.isEmpty {
                    ForEach(movies) { movie in
                        CardView(movie: movie)
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 18)
            .padding(.horizontal, 36)

//            if viewModel.paginationState == .loading {
//                LoadingPaginationStateView()
//            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .onScrollTargetVisibilityChange(idType: MovieSimple.ID.self) { onScreenCards in
            if let movies = viewModel.state.data,
               !movies.isEmpty,
               let last = movies.last,
               onScreenCards.contains(where: { $0 == last.id }),
               viewModel.paginationState == .idle
            {
                viewModel.loadMore()
            }
        }
        .overlay {
            if let error = viewModel.state.error {
                ErrorStateView(error) {
                    viewModel.load()
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let movies = viewModel.state.data, movies.isEmpty {
                EmptyStateView(String(localized: "key.nothing_found"), String(localized: "key.filter.empty")) {
                    viewModel.load()
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if viewModel.state == .loading {
                LoadingStateView()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            }
        }
        .transition(.opacity)
        .navigationTitle(viewModel.title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    viewModel.load()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(viewModel.state.data?.isEmpty != false)
            }

            if !viewModel.isCustomMovies, !viewModel.isList {
                ToolbarItemGroup(placement: .primaryAction) {
                    if viewModel.isGenre || viewModel.isCollection || viewModel.isCountry {
                        Picker("key.filter.select", selection: $viewModel.filter) {
                            ForEach(Filters.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(viewModel.state == .loading)
                    }

                    if viewModel.isCategory(.newest) {
                        Picker("key.filter.select", selection: $viewModel.newFilter) {
                            ForEach(NewFilters.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(viewModel.state == .loading)
                    }

                    if viewModel.isCategory || viewModel.isCountry {
                        Picker("key.genre.select", selection: $viewModel.filterGenre) {
                            ForEach(Genres.allCases.filter { $0 != .show || !viewModel.isCategory(.hot) }) { genre in
                                Text(genre.rawValue).tag(genre)
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(viewModel.state == .loading)
                    }
                }
            }
        }
        .task(id: isLoggedIn) {
            switch viewModel.state {
            case .data:
                break
            default:
                viewModel.load()
            }
        }
        .onChange(of: viewModel.filterGenre) {
            viewModel.load()
        }
        .onChange(of: viewModel.filter) {
            viewModel.load()
        }
        .onChange(of: viewModel.newFilter) {
            viewModel.load()
        }
        .background(.background)
    }
}

enum Genres: LocalizedStringKey, CaseIterable, Identifiable {
    case all = "key.genres.all"
    case films = "key.genres.films"
    case series = "key.genres.series"
    case cartoons = "key.genres.cartoons"
    case anime = "key.genres.anime"
    case show = "key.genres.show"

    var id: Genres { self }

    var genreCode: Int {
        switch self {
        case .all:
            0
        case .films:
            1
        case .series:
            2
        case .cartoons:
            3
        case .anime:
            82
        case .show:
            4
        }
    }
}

enum Filters: LocalizedStringKey, CaseIterable, Identifiable {
    case latest = "key.filters.latest"
    case popular = "key.filters.popular"
    case soon = "key.filters.soon"
    case watching = "key.filters.watching_now"

    var id: Filters { self }
}

enum NewFilters: LocalizedStringKey, CaseIterable, Identifiable {
    case latest = "key.filters.latest"
    case popular = "key.filters.popular"
    case watching = "key.filters.watching_now"

    var id: NewFilters { self }
}

import ComposableArchitecture
import SwiftUI

struct ListView: View {
    @State private var store: StoreOf<ListFeature>

    init(store: StoreOf<ListFeature>) {
        _store = State(initialValue: store)
    }

    init(source: ListFeature.Source) {
        self.init(store: Store(initialState: ListFeature.State(source: source)) { ListFeature() })
    }

    init(movies: [MovieSimple], title: String) {
        self.init(source: .movies(movies, title: title))
    }

    init(list: MovieList) {
        self.init(source: .list(list))
    }

    init(country: MovieCountry) {
        self.init(source: .country(country))
    }

    init(genre: MovieGenre) {
        self.init(source: .genre(genre))
    }

    init(category: Categories) {
        self.init(source: .category(category))
    }

    init(collection: MoviesCollection) {
        self.init(source: .collection(collection))
    }

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading)]

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                if let movies = store.movies.data, !movies.isEmpty {
                    ForEach(movies) { movie in
                        CardView(movie: movie)
                            .equatable()
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 18)
            .padding(.horizontal, 36)

            if store.paginationState == .loading {
                LoadingPaginationStateView()
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .onScrollTargetVisibilityChange(idType: MovieSimple.ID.self) { onScreenCards in
            if store.paginationState == .idle,
               let movies = store.movies.data,
               movies.suffix(12).contains(where: { onScreenCards.contains($0.id) })
            {
                store.send(.loadMore)
            }
        }
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .overlay {
            if let error = store.movies.error {
                ErrorStateView(error) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let movies = store.movies.data, movies.isEmpty {
                EmptyStateView(String(localized: "key.nothing_found"), String(localized: "key.filter.empty")) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if store.movies == .loading {
                LoadingStateView()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            }
        }
        .transition(.opacity)
        .navigationTitle(store.title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    store.send(.reload)
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(store.movies.data?.isEmpty != false)
            }

            if !store.isCustomMovies, !store.isList {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if store.isGenre || store.isCollection || store.isCountry {
                            Picker("key.filter.select", selection: $store.filter) {
                                ForEach(Filters.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.inline)
                        }

                        if store.state.isCategory(.newest) {
                            Picker("key.filter.select", selection: $store.newFilter) {
                                ForEach(NewFilters.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.inline)
                        }

                        if store.isCategory || store.isCountry {
                            Picker("key.genre.select", selection: $store.filterGenre) {
                                ForEach(Genres.allCases.filter { $0 != .show || !store.state.isCategory(.hot) }) { genre in
                                    Text(genre.rawValue).tag(genre)
                                }
                            }
                            .pickerStyle(.inline)
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .menuStyle(.button)
                    .menuIndicator(.hidden)
                    .disabled(store.movies == .loading)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .background(.background)
    }
}

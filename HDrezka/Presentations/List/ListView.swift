import ComposableArchitecture
import SwiftUI

struct ListView: View {
    @Bindable var store: StoreOf<ListFeature>

    var body: some View {
        MoviesGridView(store.movies.data, pagination: store.pagination.state) {
            store.send(.loadMore)
        }
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .dataStateOverlay(store.movies, empty: String(localized: "key.nothing_found"), String(localized: "key.filter.empty")) {
            store.send(.reload)
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

                        if store.source == .category(.newest) {
                            Picker("key.filter.select", selection: $store.newFilter) {
                                ForEach(NewFilters.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.inline)
                        }

                        if store.isCategory || store.isCountry {
                            Picker("key.genre.select", selection: $store.filterGenre) {
                                ForEach(Genres.allCases.filter { $0 != .show || store.source != .category(.hot) }) { genre in
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
                    .disabled(store.movies.isLoading)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .background(.background)
    }
}

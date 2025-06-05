import Defaults
import SwiftUI

struct ListView: View {
    @StateObject private var vm: ListViewModel

    init(movies: [MovieSimple], title: String) {
        self._vm = StateObject(wrappedValue: ListViewModel(movies: movies, title: title))
    }

    init(list: MovieList) {
        self._vm = StateObject(wrappedValue: ListViewModel(list: list))
    }

    init(country: MovieCountry) {
        self._vm = StateObject(wrappedValue: ListViewModel(country: country))
    }

    init(genre: MovieGenre) {
        self._vm = StateObject(wrappedValue: ListViewModel(genre: genre))
    }

    init(category: Categories) {
        self._vm = StateObject(wrappedValue: ListViewModel(category: category))
    }

    init(collection: MoviesCollection) {
        self._vm = StateObject(wrappedValue: ListViewModel(collection: collection))
    }

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading)]

    @State private var showBar: Bool = false

    @Default(.isLoggedIn) private var isLoggedIn

    var body: some View {
        Group {
            if let error = vm.state.error {
                ErrorStateView(error, vm.title) {
                    vm.load()
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let movies = vm.state.data {
                if movies.isEmpty {
                    EmptyStateView(String(localized: "key.nothing_found"), vm.title, String(localized: "key.filter.empty")) {
                        vm.load()
                    }
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
                } else {
                    VStack {
                        ScrollView(.vertical) {
                            VStack(spacing: 18) {
                                VStack(alignment: .leading) {
                                    Spacer()

                                    Text(vm.title)
                                        .font(.largeTitle.weight(.semibold))
                                        .lineLimit(1)

                                    Spacer()

                                    Divider()
                                }
                                .frame(height: 52)

                                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                                    ForEach(movies) { movie in
                                        CardView(movie: movie)
                                            .task {
                                                if movies.last == movie, vm.paginationState == .idle {
                                                    vm.loadMore()
                                                }
                                            }
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .padding(.vertical, 52)
                            .padding(.horizontal, 36)
                            .onGeometryChange(for: Bool.self) { geometry in
                                -geometry.frame(in: .named("scroll")).origin.y / 52 >= 1
                            } action: { showBar in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    self.showBar = showBar
                                }
                            }
                        }
                        .coordinateSpace(name: "scroll")
                        .scrollIndicators(.never)

                        if vm.paginationState == .loading {
                            LoadingPaginationStateView()
                        }
                    }
                }
            } else {
                LoadingStateView(vm.title)
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
            }
        }
        .navigationBar(title: vm.title, showBar: showBar, navbar: {
            if let movies = vm.state.data, !movies.isEmpty {
                Button {
                    vm.load()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                .keyboardShortcut("r", modifiers: .command)
            }
        }, toolbar: {
            if vm.state != .loading, !vm.isCustomMovies, !vm.isList {
                Image(systemName: "line.3.horizontal.decrease.circle")

                if vm.isGenre || vm.isCollection || vm.isCountry {
                    Picker("key.filter.select", selection: $vm.filter) {
                        ForEach(Filters.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .viewModifier { view in
                        if #available(macOS 14, *) {
                            view
                                .buttonStyle(.accessoryBar)
                                .controlSize(.large)
                        } else {
                            view
                        }
                    }
                    .background(.tertiary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                    }
                }

                if vm.isCategory(.newest) {
                    Picker("key.filter.select", selection: $vm.newFilter) {
                        ForEach(NewFilters.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .viewModifier { view in
                        if #available(macOS 14, *) {
                            view
                                .buttonStyle(.accessoryBar)
                                .controlSize(.large)
                        } else {
                            view
                        }
                    }
                    .background(.tertiary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                    }

                    Divider()
                        .padding(.vertical, 18)
                }

                if vm.isCountry {
                    Divider()
                        .padding(.vertical, 18)
                }

                if vm.isCategory || vm.isCountry {
                    Picker("key.genre.select", selection: $vm.filterGenre) {
                        ForEach(Genres.allCases.filter { $0 != .show || !vm.isCategory(.hot) }) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .viewModifier { view in
                        if #available(macOS 14, *) {
                            view
                                .buttonStyle(.accessoryBar)
                                .controlSize(.large)
                        } else {
                            view
                        }
                    }
                    .background(.tertiary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                    }
                }
            }
        })
        .load(isLoggedIn) {
            switch vm.state {
            case .data:
                break
            default:
                vm.load()
            }
        }
        .customOnChange(of: vm.filterGenre) {
            vm.load()
        }
        .customOnChange(of: vm.filter) {
            vm.load()
        }
        .customOnChange(of: vm.newFilter) {
            vm.load()
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

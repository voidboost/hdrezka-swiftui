import Defaults
import SwiftUI

struct ListView: View {
    private let customMovies: [MovieSimple]?
    private let list: MovieList?
    private let country: MovieCountry?
    private let genre: MovieGenre?
    private let category: Categories?
    private let collection: MoviesCollection?
    private let customTitle: String?

    @StateObject private var vm = ListViewModel()

    @Default(.isLoggedIn) private var isLoggedIn

    @State private var showBar: Bool = false

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading)]

    init(customMovies: [MovieSimple], title: String) {
        self.customMovies = customMovies
        self.list = nil
        self.country = nil
        self.genre = nil
        self.category = nil
        self.collection = nil
        self.customTitle = title
    }

    init(list: MovieList) {
        self.customMovies = nil
        self.list = list
        self.country = nil
        self.genre = nil
        self.category = nil
        self.collection = nil
        self.customTitle = nil
    }

    init(country: MovieCountry) {
        self.customMovies = nil
        self.list = nil
        self.country = country
        self.genre = nil
        self.category = nil
        self.collection = nil
        self.customTitle = nil
    }

    init(genre: MovieGenre) {
        self.customMovies = nil
        self.list = nil
        self.country = nil
        self.genre = genre
        self.category = nil
        self.collection = nil
        self.customTitle = nil
    }

    init(category: Categories) {
        self.customMovies = nil
        self.list = nil
        self.country = nil
        self.genre = nil
        self.category = category
        self.collection = nil
        self.customTitle = nil
    }

    init(collection: MoviesCollection) {
        self.customMovies = nil
        self.list = nil
        self.country = nil
        self.genre = nil
        self.category = nil
        self.collection = collection
        self.customTitle = nil
    }

    var body: some View {
        Group {
            if let error = vm.state.error {
                ErrorStateView(error, title) {
                    vm.load(movies: customMovies, list: list, country: country, genre: genre, collection: collection, category: category)
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let movies = vm.state.data {
                if movies.isEmpty {
                    EmptyStateView(String(localized: "key.nothing_found"), title, String(localized: "key.filter.empty")) {
                        vm.load(movies: customMovies, list: list, country: country, genre: genre, collection: collection, category: category)
                    }
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
                } else {
                    VStack {
                        ScrollView(.vertical) {
                            VStack(spacing: 18) {
                                VStack(alignment: .leading) {
                                    Spacer()

                                    Text(title)
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
                                                    vm.loadMore(movies: customMovies, list: list, country: country, genre: genre, collection: collection, category: category)
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
                LoadingStateView(title)
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
            }
        }
        .navigationBar(title: title, showBar: showBar, navbar: {
            if let movies = vm.state.data, !movies.isEmpty {
                Button {
                    vm.load(movies: customMovies, list: list, country: country, genre: genre, collection: collection, category: category)
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                .keyboardShortcut("r", modifiers: .command)
            }
        }, toolbar: {
            if vm.state != .loading, customMovies == nil, list == nil {
                Image(systemName: "line.3.horizontal.decrease.circle")

                if genre != nil || collection != nil || country != nil {
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

                if let category, case .newest = category {
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

                if country != nil {
                    Divider()
                        .padding(.vertical, 18)
                }

                if category != nil || country != nil {
                    Picker("key.genre.select", selection: $vm.filterGenre) {
                        ForEach(Genres.allCases.filter { $0 != .show || category != .hot }) { g in
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
                vm.load(movies: customMovies, list: list, country: country, genre: genre, collection: collection, category: category)
            }
        }
        .customOnChange(of: vm.filterGenre) {
            vm.load(movies: customMovies, list: list, country: country, genre: genre, collection: collection, category: category)
        }
        .customOnChange(of: vm.filter) {
            vm.load(movies: customMovies, list: list, country: country, genre: genre, collection: collection, category: category)
        }
        .customOnChange(of: vm.newFilter) {
            vm.load(movies: customMovies, list: list, country: country, genre: genre, collection: collection, category: category)
        }
        .background(.background)
    }

    private var title: String {
        if let title = vm.title, !title.isEmpty {
            return title
        } else if let title = list?.name, !title.isEmpty {
            return title
        } else if let title = country?.name, !title.isEmpty {
            return title
        } else if let title = genre?.name, !title.isEmpty {
            return title
        } else if let title = category?.localized, !title.isEmpty {
            return title
        } else if let title = collection?.name, !title.isEmpty {
            return title
        } else if let title = customTitle, !title.isEmpty {
            return title
        } else {
            return String(localized: "key.list")
        }
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

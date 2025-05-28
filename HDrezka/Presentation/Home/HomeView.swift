import Defaults
import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    @State private var isSeriesUpdatesPresented: Bool = false

    @State private var showBar: Bool = false

    @Default(.isLoggedIn) private var isLoggedIn

    private let title = String(localized: "key.home")

    var body: some View {
        Group {
            if let error = vm.state.error {
                ErrorStateView(error, title) {
                    vm.load()
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let categories = vm.state.data {
                if categories.isEmpty {
                    EmptyStateView(String(localized: "key.home.empty"), title) {
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

                                    Text(title)
                                        .font(.largeTitle.weight(.semibold))
                                        .lineLimit(1)

                                    Spacer()

                                    Divider()
                                }
                                .frame(height: 52)
                                .padding(.horizontal, 36)

                                LazyVStack(alignment: .leading, spacing: 18) {
                                    ForEach(categories) { category in
                                        CategorySection(title: category.title, category: category.category, movies: category.movies)
                                            .task {
                                                if categories.last == category, vm.paginationState == .idle {
                                                    vm.loadMore()
                                                }
                                            }

                                        if category.category != Categories.allCases.last {
                                            Divider()
                                                .padding(.horizontal, 36)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 52)
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

                        if let error = vm.paginationState.error {
                            VStack(alignment: .center) {
                                Text(error.localizedDescription)
                                    .lineLimit(nil)

                                Button {
                                    vm.paginationState = .idle
                                    vm.loadMore()
                                } label: {
                                    Text("key.retry")
                                        .foregroundStyle(.accent)
                                        .highlightOnHover()
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 10)
                        } else if vm.paginationState == .loading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, 10)
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
            if let categories = vm.state.data, !categories.isEmpty {
                Button {
                    vm.load()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                .keyboardShortcut("r", modifiers: .command)
            }
        }, toolbar: {
            if case .data = vm.state {
                Button {
                    isSeriesUpdatesPresented = true
                } label: {
                    Image(systemName: "bell")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
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
        .background(.background)
        .sheet(isPresented: $isSeriesUpdatesPresented) {
            SeriesUpdatesSheetView()
        }
    }

    private struct CategorySection: View {
        private let title: String

        private let category: Categories

        private let movies: [MovieSimple]

        @EnvironmentObject private var appState: AppState

        init(title: String, category: Categories, movies: [MovieSimple]) {
            self.title = title
            self.category = category
            self.movies = movies
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 9) {
                    Text(title).font(.system(size: 22, weight: .semibold))

                    Spacer()

                    Button {
                        appState.path.append(.category(category))
                    } label: {
                        HStack(alignment: .center) {
                            Text("key.see_all")
                                .font(.system(size: 12))
                                .foregroundStyle(.accent)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.accent)
                        }
                        .highlightOnHover()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 36)

                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 18) {
                        ForEach(movies) { movie in
                            CardView(movie: movie, reservesSpace: true)
                                .frame(width: 150)
                        }
                    }
                    .padding(.horizontal, 36)
                }
                .scrollIndicators(.never)
            }
        }
    }
}

import Defaults
import SwiftUI

struct HomeView: View {
    private let title = String(localized: "key.home")

    @StateObject private var viewModel = HomeViewModel()

    @State private var showBar: Bool = false

    @Default(.isLoggedIn) private var isLoggedIn

    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if let error = viewModel.state.error {
                ErrorStateView(error, title) {
                    viewModel.load()
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let categories = viewModel.state.data {
                if categories.isEmpty {
                    EmptyStateView(String(localized: "key.home.empty"), title) {
                        viewModel.load()
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
                                        Section {
                                            ScrollView(.horizontal) {
                                                LazyHStack(alignment: .top, spacing: 18) {
                                                    ForEach(category.movies) { movie in
                                                        CardView(movie: movie, reservesSpace: true)
                                                            .frame(width: 150)
                                                    }
                                                }
                                                .padding(.horizontal, 36)
                                            }
                                            .scrollIndicators(.never)
                                        } header: {
                                            HStack(alignment: .center, spacing: 9) {
                                                Text(category.title).font(.system(size: 22, weight: .semibold))

                                                Spacer()

                                                Button {
                                                    appState.path.append(.category(category.category))
                                                } label: {
                                                    HStack(alignment: .center) {
                                                        Text("key.see_all")
                                                            .font(.system(size: 12))
                                                            .foregroundStyle(Color.accentColor)

                                                        Image(systemName: "chevron.right")
                                                            .font(.system(size: 12))
                                                            .foregroundStyle(Color.accentColor)
                                                    }
                                                    .highlightOnHover()
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .padding(.horizontal, 36)
                                        }
                                        .task {
                                            if categories.last == category, viewModel.paginationState == .idle {
                                                viewModel.loadMore()
                                            }
                                        }

                                        if category.category != Categories.allCases.last {
                                            Divider().padding(.horizontal, 36)
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

                        if let error = viewModel.paginationState.error {
                            ErrorPaginationStateView(error) {
                                viewModel.loadMore(reset: true)
                            }
                        } else if viewModel.paginationState == .loading {
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
            if let categories = viewModel.state.data, !categories.isEmpty {
                Button {
                    viewModel.load()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                .keyboardShortcut("r", modifiers: .command)
            }
        }, toolbar: {
            if case .data = viewModel.state {
                Button {
                    viewModel.isSeriesUpdatesPresented = true
                } label: {
                    Image(systemName: "bell")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
            }
        })
        .task(id: isLoggedIn) {
            switch viewModel.state {
            case .data:
                break
            default:
                viewModel.load()
            }
        }
        .background(.background)
        .sheet(isPresented: $viewModel.isSeriesUpdatesPresented) {
            SeriesUpdatesSheetView()
        }
    }
}

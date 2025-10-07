import Defaults
import SwiftUI

struct HomeView: View {
    private let title = String(localized: "key.home")

    @State private var viewModel = HomeViewModel()

    @Default(.isLoggedIn) private var isLoggedIn

    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let categories = viewModel.state.data, !categories.isEmpty {
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
                                    appState.append(.category(category.category))
                                } label: {
                                    HStack(alignment: .center) {
                                        Text("key.see_all")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.accentColor)

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .buttonStyle(.accessoryBar)
                            }
                            .padding(.horizontal, 36)
                        }

                        if category.category != Categories.allCases.last {
                            Divider().padding(.horizontal, 36)
                        }
                    }

                    if let error = viewModel.paginationState.error {
                        ErrorPaginationStateView(error) {
                            viewModel.loadMore(reset: true)
                        }
                    } else if viewModel.paginationState == .loading {
                        LoadingPaginationStateView()
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 18)
        }
        .scrollIndicators(.visible, axes: .vertical)
        .onScrollTargetVisibilityChange(idType: Category.ID.self) { onScreenCategories in
            if let categories = viewModel.state.data,
               !categories.isEmpty,
               let last = categories.last,
               onScreenCategories.contains(where: { $0 == last.id }),
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
            } else if let categories = viewModel.state.data, categories.isEmpty {
                EmptyStateView(String(localized: "key.home.empty")) {
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
        .navigationTitle(title)
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

            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.isSeriesUpdatesPresented = true
                } label: {
                    Image(systemName: "bell")
                }
                .disabled(viewModel.state.data == nil)
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
        .background(.background)
        .sheet(isPresented: $viewModel.isSeriesUpdatesPresented) {
            SeriesUpdatesSheetView()
        }
    }
}

import Defaults
import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    @FocusState private var searchFocus

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading),
    ]

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
                    viewModel.load(force: true)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let movies = viewModel.state.data, movies.isEmpty {
                EmptyStateView(String(localized: "key.nothing_found"), String(localized: "key.search.empty"))
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            } else if viewModel.state == .loading {
                LoadingStateView()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            }
        }
        .searchable(text: $viewModel.query, placement: .toolbar)
        .searchFocused($searchFocus)
        .transition(.opacity)
        .navigationTitle(viewModel.title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    viewModel.load(force: true)
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(viewModel.state.data?.isEmpty != false)
            }
        }
        .background(.background)
        .task(id: isLoggedIn) {
            switch viewModel.state {
            case .data:
                break
            default:
                viewModel.load(force: true)
            }

            searchFocus = true
        }
        .onChange(of: viewModel.query) {
            viewModel.load(force: viewModel.query.trim().isEmpty)
        }
    }
}

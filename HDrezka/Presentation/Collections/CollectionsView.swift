import Defaults
import SwiftUI

struct CollectionsView: View {
    private let title = String(localized: "key.collections")

    @State private var viewModel = CollectionsViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: .infinity), spacing: 18, alignment: .topLeading),
    ]

    @State private var showBar: Bool = false

    @Default(.isLoggedIn) private var isLoggedIn

    var body: some View {
        Group {
            if let error = viewModel.state.error {
                ErrorStateView(error, title) {
                    viewModel.load()
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let collections = viewModel.state.data {
                if collections.isEmpty {
                    EmptyStateView(String(localized: "key.collections.empty"), title) {
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

                                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                                    ForEach(collections) { collection in
                                        CollectionCardView(collection: collection)
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .padding(.vertical, 52)
                            .padding(.horizontal, 36)
                        }
                        .scrollIndicators(.never)
                        .onScrollGeometryChange(for: Bool.self) { geometry in
                            geometry.contentOffset.y >= 52
                        } action: { _, showBar in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                self.showBar = showBar
                            }
                        }
                        .onScrollTargetVisibilityChange(idType: MoviesCollection.ID.self) { onScreenCards in
                            if let last = collections.last, onScreenCards.contains(where: { $0 == last.id }), viewModel.paginationState == .idle {
                                viewModel.loadMore()
                            }
                        }

                        if viewModel.paginationState == .loading {
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
            if let collections = viewModel.state.data, !collections.isEmpty {
                Button {
                    viewModel.load()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                .keyboardShortcut("r", modifiers: .command)
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
    }
}

import Defaults
import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()

    private let searchText: String

    init(searchText: String) {
        self.searchText = searchText
    }

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading)
    ]

    @State private var showBar: Bool = false

    @Default(.isLoggedIn) private var isLoggedIn

    var body: some View {
        Group {
            if let error = vm.state.error {
                ErrorStateView(error, vm.title) {
                    vm.load(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let movies = vm.state.data {
                if movies.isEmpty {
                    EmptyStateView(String(localized: "key.nothing_found"), vm.title, String(localized: "key.search.empty"))
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
                                                    vm.loadMore(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                                                }
                                            }
                                    }
                                }
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
                    vm.load(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                .keyboardShortcut("r", modifiers: .command)
            }
        })
        .load(isLoggedIn) {
            switch vm.state {
            case .data:
                break
            default:
                vm.load(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        .background(.background)
        .customOnChange(of: searchText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            vm.load(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

import Defaults
import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()

    @Binding private var searchText: String
    @State private var searchWork: DispatchWorkItem?
    @State private var title: String

    @Default(.isLoggedIn) private var isLoggedIn

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading)
    ]

    @State private var showBar: Bool = false

    init(searchText: Binding<String>) {
        self._searchText = searchText

        if !searchText.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.title = String(localized: "key.search.result-\(searchText.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines))")
        } else {
            self.title = String(localized: "key.search")
        }
    }

    var body: some View {
        Group {
            if let error = vm.state.error {
                ErrorStateView(error, title) {
                    vm.reload(query: searchText)
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let movies = vm.state.data {
                if movies.isEmpty {
                    EmptyStateView(String(localized: "key.nothing_found"), title, String(localized: "key.search.empty"))
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
                                                    vm.nextPage(query: searchText)
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
            if let movies = vm.state.data, !movies.isEmpty {
                Button {
                    vm.reload(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
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
                vm.reload(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        .background(.background)
        .customOnChange(of: searchText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            searchWork?.cancel()

            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                searchWork = DispatchWorkItem {
                    if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        title = String(localized: "key.search.result-\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))")
                    } else {
                        title = String(localized: "key.search")
                    }

                    vm.reload(query: searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                }

                if let searchWork {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: searchWork)
                }
            }
        }
    }
}

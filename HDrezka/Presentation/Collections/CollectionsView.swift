import Defaults
import SwiftUI

struct CollectionsView: View {
    @StateObject private var vm = CollectionsViewModel()

    @State private var showBar: Bool = false

    @Default(.isLoggedIn) private var isLoggedIn

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: .infinity), spacing: 18, alignment: .topLeading)
    ]

    private let title = String(localized: "key.collections")

    var body: some View {
        Group {
            if let error = vm.state.error {
                ErrorStateView(error, title) {
                    vm.load()
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let collections = vm.state.data {
                if collections.isEmpty {
                    EmptyStateView(String(localized: "key.collections.empty"), title) {
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

                                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                                    ForEach(collections) { collection in
                                        CollectionCardView(collection: collection)
                                            .task {
                                                if collections.last == collection, vm.paginationState == .idle {
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
                LoadingStateView(title)
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
            }
        }
        .navigationBar(title: title, showBar: showBar, navbar: {
            if let collections = vm.state.data, !collections.isEmpty {
                Button {
                    vm.load()
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
                vm.load()
            }
        }
        .background(.background)
    }
}

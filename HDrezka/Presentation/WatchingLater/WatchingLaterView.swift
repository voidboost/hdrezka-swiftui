import Combine
import Defaults
import FactoryKit
import SwiftData
import SwiftUI

struct WatchingLaterView: View {
    private let title = String(localized: "key.watching_later")

    @State private var viewModel = WatchingLaterViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading),
    ]

    @State private var showBar: Bool = false

    @Default(.isLoggedIn) private var isLoggedIn

    @Environment(\.modelContext) private var modelContext

    @Query private var playerPositions: [PlayerPosition]

    var body: some View {
        Group {
            if let error = viewModel.state.error {
                ErrorStateView(error, title) {
                    viewModel.load()
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let movies = viewModel.state.data {
                if movies.isEmpty {
                    EmptyStateView(String(localized: "key.watching_later.empty"), title, String(localized: "key.watching_later.empty.description")) {
                        viewModel.load()
                    }
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
                } else {
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
                                    WatchingLaterCardView(movie: movie)
                                        .contextMenu {
                                            Button {
                                                viewModel.switchWatchedItem(movie: movie)
                                            } label: {
                                                Text(movie.watched ? String(localized: "key.mark.unwatched") : String(localized: "key.mark.watched"))
                                            }

                                            Button {
                                                viewModel.removeWatchingItem(movie: movie)

                                                playerPositions
                                                    .filter { $0.id == movie.watchLaterId.id }
                                                    .forEach { modelContext.delete($0) }
                                            } label: {
                                                Text("key.delete")
                                            }
                                        }
                                }
                            }
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
                }
            } else {
                LoadingStateView(title)
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
            }
        }
        .navigationBar(title: title, showBar: showBar, navbar: {
            if let movies = viewModel.state.data, !movies.isEmpty {
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
        .alert("key.ops", isPresented: $viewModel.isErrorPresented) {
            Button(role: .cancel) {} label: {
                Text("key.ok")
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
        .background(.background)
    }
}

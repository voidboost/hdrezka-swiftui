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

    @Environment(\.modelContext) private var modelContext

    @Query private var playerPositions: [PlayerPosition]

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                if let movies = viewModel.state.data, !movies.isEmpty {
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
            .padding(.vertical, 18)
            .padding(.horizontal, 36)
        }
        .scrollIndicators(.visible, axes: .vertical)
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .overlay {
            if let error = viewModel.state.error {
                ErrorStateView(error) {
                    viewModel.load()
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let movies = viewModel.state.data, movies.isEmpty {
                EmptyStateView(String(localized: "key.watching_later.empty"), String(localized: "key.watching_later.empty.description")) {
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
        }
        .onAppear {
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

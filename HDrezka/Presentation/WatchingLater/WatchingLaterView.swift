import Combine
import CoreData
import Defaults
import FactoryKit
import SwiftUI

struct WatchingLaterView: View {
    @State private var vm = WatchingLaterViewModel()

    @State private var subscriptions: Set<AnyCancellable> = []

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading)
    ]

    @State private var error: Error?
    @State private var isErrorPresented: Bool = false

    @State private var showBar: Bool = false

    @Injected(\.switchWatchedItemUseCase) private var switchWatchedItemUseCase
    @Injected(\.removeWatchingItemUseCase) private var removeWatchingItemUseCase

    @Default(.isLoggedIn) private var isLoggedIn

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(fetchRequest: PlayerPosition.fetch()) private var playerPositions: FetchedResults<PlayerPosition>

    private let title = String(localized: "key.watching_later")

    var body: some View {
        Group {
            if let error = vm.state.error {
                ErrorStateView(error, title) {
                    vm.reload()
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if var movies = vm.state.data {
                if movies.isEmpty {
                    EmptyStateView(String(localized: "key.watching_later.empty"), title, String(localized: "key.watching_later.empty.description")) {
                        vm.reload()
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
                                                switchWatchedItemUseCase(item: movie)
                                                    .receive(on: DispatchQueue.main)
                                                    .sink { completion in
                                                        guard case let .failure(error) = completion else { return }

                                                        self.error = error
                                                        self.isErrorPresented = true
                                                    } receiveValue: { result in
                                                        if result {
                                                            if let index = movies.firstIndex(of: movie) {
                                                                movies[index].watched.toggle()

                                                                if !movie.watched {
                                                                    movies.move(
                                                                        fromOffsets: IndexSet(integer: index),
                                                                        toOffset: movies.count
                                                                    )
                                                                }

                                                                withAnimation(.easeInOut) {
                                                                    vm.state = .data(movies)
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .store(in: &subscriptions)
                                            } label: {
                                                Text(movie.watched ? String(localized: "key.mark.unwatched") : String(localized: "key.mark.watched"))
                                            }

                                            Button {
                                                removeWatchingItemUseCase(item: movie)
                                                    .receive(on: DispatchQueue.main)
                                                    .sink { completion in
                                                        guard case let .failure(error) = completion else { return }

                                                        self.error = error
                                                        self.isErrorPresented = true
                                                    } receiveValue: { delete in
                                                        if delete {
                                                            movies.removeAll(where: {
                                                                $0.id == movie.id
                                                            })

                                                            withAnimation(.easeInOut) {
                                                                vm.state = .data(movies)
                                                            }

                                                            playerPositions
                                                                .filter { $0.id == movie.watchLaterId.id }
                                                                .forEach(viewContext.delete)

                                                            viewContext.saveContext()
                                                        }
                                                    }
                                                    .store(in: &subscriptions)
                                            } label: {
                                                Text("key.delete")
                                            }
                                        }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .padding(.vertical, 52)
                        .padding(.horizontal, 36)
                        .onGeometryChange(for: Bool.self) { geometry in
                            -geometry.frame(in: .scrollView).origin.y / 52 >= 1
                        } action: { showBar in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                self.showBar = showBar
                            }
                        }
                    }
                    .scrollIndicators(.never)
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
                    vm.reload()
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
                vm.reload()
            }
        }
        .alert("key.ops", isPresented: $isErrorPresented) {
            Button(role: .cancel) {} label: {
                Text("key.ok")
            }
        } message: {
            if let error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
        .background(.background)
    }
}

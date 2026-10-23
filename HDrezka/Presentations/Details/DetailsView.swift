import ComposableArchitecture
import Defaults
import SwiftUI

struct DetailsView: View {
    private let title: String?

    @State private var store: StoreOf<DetailsFeature>

    init(movie: MovieSimple) {
        title = movie.name
        _store = State(initialValue: Store(initialState: DetailsFeature.State(id: movie.movieId)) { DetailsFeature() })
    }

    @State private var isBookmarksPresented = false
    @State private var isCreateBookmarkPresented = false
    @State private var isSchedulePresented = false

    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.mirror) private var mirror

    @State private var topSafeAreaInset: CGFloat = .zero

    private var content: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let details = store.details.data {
                    DetailsComponentView(
                        details: details,
                        trailerId: store.trailerId,
                        topSafeAreaInset: topSafeAreaInset,
                        isSchedulePresented: $isSchedulePresented
                    )
                    .environment(store)
                }
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .ignoresSafeArea(edges: .top)
        .contentMargins(.top, topSafeAreaInset, for: .scrollIndicators)
        .overlay {
            if let error = store.details.error {
                ErrorStateView(error) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if store.details == .loading {
                LoadingStateView()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            }
        }
        .transition(.opacity)
        .navigationTitle(store.details.data?.nameRussian ?? title ?? "")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    store.send(.reload)
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(store.details.data == nil)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if let details = store.details.data {
                    NavigationLink(value: Destinations.comments(details)) {
                        HStack(alignment: .center, spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right")

                            if let details = store.details.data, details.commentsCount > 0 {
                                Text(verbatim: "(\(details.commentsCount))")
                            }
                        }
                    }
                }

                if isLoggedIn {
                    Button {
                        isBookmarksPresented = true
                    } label: {
                        Image(systemName: "bookmark")
                    }
                    .disabled(store.details.data == nil)
                }

                ShareLink(item: (!_mirror.isDefaultValue ? mirror : Const.redirectMirror).appending(path: store.id, directoryHint: .notDirectory)) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(store.details.data == nil)
            }
        }
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.safeAreaInsets.top
        } action: { inset in
            topSafeAreaInset = inset
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(isPresented: $isBookmarksPresented) {
            BookmarksSheetView(id: store.id, isCreateBookmarkPresented: $isCreateBookmarkPresented)
        }
        .sheet(isPresented: $isCreateBookmarkPresented) {
            CreateBookmarkSheetView()
        }
        .sheet(isPresented: $isSchedulePresented) {
            if let details = store.details.data, let schedule = details.schedule, !schedule.isEmpty {
                ScheduleSheetView(schedule: schedule)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .dialogSeverity(.critical)
        .onChange(of: isCreateBookmarkPresented) {
            isBookmarksPresented = !isCreateBookmarkPresented
        }
        .background(.background)
    }

    var body: some View {
        content
            .navigationDestination(item: $store.countryDestination) {
                ListView(country: $0)
            }
            .navigationDestination(item: $store.genreDestination) {
                ListView(genre: $0)
            }
            .navigationDestination(item: $store.personDestination) {
                PersonView(person: $0)
            }
            .navigationDestination(item: $store.listDestination) {
                ListView(list: $0)
            }
            .navigationDestination(item: $store.collectionDestination) {
                ListView(collection: $0)
            }
    }
}

import ComposableArchitecture
import Defaults
import SwiftUI

struct DetailsView: View {
    @Bindable var store: StoreOf<DetailsFeature>

    @State private var isSchedulePresented = false

    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.mirror) private var mirror

    @State private var topSafeAreaInset: CGFloat = .zero

    var body: some View {
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
            } else if store.details.isLoading {
                LoadingStateView()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            }
        }
        .transition(.opacity)
        .navigationTitle(store.details.data?.nameRussian ?? store.title ?? "")
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
                    NavigationLink(route: .comments(details)) {
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
                        store.send(.bookmarksTapped)
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
        .sheet(item: $store.scope(state: \.destination?.bookmarks, action: \.destination.bookmarks)) { store in
            BookmarksSheetView(store: store)
        }
        .sheet(item: $store.scope(state: \.destination?.createBookmark, action: \.destination.createBookmark)) { store in
            CreateBookmarkSheetView(store: store)
        }
        .sheet(isPresented: $isSchedulePresented) {
            if let details = store.details.data, let schedule = details.schedule, !schedule.isEmpty {
                ScheduleSheetView(schedule: schedule)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .dialogSeverity(.critical)
        .background(.background)
    }
}

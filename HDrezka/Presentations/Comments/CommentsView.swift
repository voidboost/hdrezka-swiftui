import ComposableArchitecture
import SwiftUI

struct CommentsView: View {
    @Bindable var store: StoreOf<CommentsFeature>

    var body: some View {
        ScrollView(.vertical) {
            if store.comments.data?.isEmpty == false, store.reply == nil {
                CommentTextAreaView()
                    .padding(.top, 18)
                    .padding(.horizontal, 36)
                    .environment(store)
            }

            LazyVStack(alignment: .leading, spacing: 16) {
                if let comments = store.comments.data, !comments.isEmpty {
                    ForEach(comments) { comment in
                        CommentView(comment: comment)
                            .equatable()
                            .environment(store)
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 18)
            .padding(.horizontal, 36)

            if store.paginationState == .loading {
                LoadingPaginationStateView()
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .onScrollTargetVisibilityChange(idType: Comment.ID.self) { onScreenComments in
            if store.paginationState == .idle,
               let comments = store.comments.data,
               !comments.isEmpty,
               let last = comments.last,
               onScreenComments.contains(where: { $0 == last.id })
            {
                store.send(.loadMore)
            }
        }
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .overlay {
            if let error = store.comments.error {
                ErrorStateView(error) {
                    store.send(.reload)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let comments = store.comments.data, comments.isEmpty {
                ScrollView(.vertical) {
                    CommentTextAreaView()
                        .padding(.vertical, 18)
                        .padding(.horizontal, 36)
                        .environment(store)
                }
                .scrollIndicators(.visible, axes: .vertical)
                .viewModifier { view in
                    if #available(macOS 26, *) {
                        view.scrollEdgeEffectStyle(.soft, for: .all)
                    } else {
                        view
                    }
                }
            } else if store.comments.isLoading {
                LoadingStateView()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            }
        }
        .transition(.opacity)
        .navigationTitle(store.title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    store.send(.reload)
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(store.comments.data?.isEmpty != false)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .dialogSeverity(.critical)
        .alert($store.scope(state: \.moderationAlert, action: \.moderationAlert))
        .dialogSeverity(.automatic)
        .sheet(isPresented: $store.isCommentPresented) {
            VStack(alignment: .center, spacing: 25) {
                if let comment = store.comment {
                    ScrollView(.vertical) {
                        CommentView(comment: comment)
                            .equatable()
                            .environment(store)
                    }
                    .scrollIndicators(.visible, axes: .vertical)
                } else {
                    ProgressView()
                }

                Button {
                    store.isCommentPresented = false
                } label: {
                    Text("key.done")
                        .frame(width: 250, height: 30)
                        .contentShape(.rect(cornerRadius: 6))
                        .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 35)
            .padding(.top, 35)
            .padding(.bottom, 25)
            .frame(width: 650)
            .frame(maxHeight: 520)
        }
        .sheet(item: $store.scope(state: \.reportComment, action: \.reportComment)) { store in
            CommentReportSheetView(store: store)
        }
        .confirmationDialog($store.scope(state: \.deleteDialog, action: \.deleteDialog))
        .background(.background)
    }
}

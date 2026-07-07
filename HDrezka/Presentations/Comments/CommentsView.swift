import SwiftUI

struct CommentsView: View {
    private let title: String

    @State private var viewModel: CommentsViewModel

    init(details: MovieDetailed) {
        title = details.commentsCount > 0 ? String(localized: "key.comments-\(details.commentsCount)") : String(localized: "key.comments")
        viewModel = CommentsViewModel(id: details.movieId, adb: details.adb, type: details.type)
    }

    var body: some View {
        ScrollView(.vertical) {
            if viewModel.state.data?.isEmpty == false, viewModel.reply == nil {
                CommentTextAreaView()
                    .padding(.top, 18)
                    .padding(.horizontal, 36)
                    .environment(viewModel)
            }

            LazyVStack(alignment: .leading, spacing: 16) {
                if let comments = viewModel.state.data, !comments.isEmpty {
                    ForEach(comments) { comment in
                        CommentView(comment: comment)
                            .equatable()
                            .environment(viewModel)
                    }
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 18)
            .padding(.horizontal, 36)

            if viewModel.paginationState == .loading {
                LoadingPaginationStateView()
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .onScrollTargetVisibilityChange(idType: Comment.ID.self) { onScreenComments in
            if viewModel.paginationState == .idle,
               let comments = viewModel.state.data,
               !comments.isEmpty,
               let last = comments.last,
               onScreenComments.contains(where: { $0 == last.id })
            {
                viewModel.loadMore()
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
            if let error = viewModel.state.error {
                ErrorStateView(error) {
                    viewModel.load()
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if let comments = viewModel.state.data, comments.isEmpty {
                ScrollView(.vertical) {
                    CommentTextAreaView()
                        .padding(.vertical, 18)
                        .padding(.horizontal, 36)
                        .environment(viewModel)
                }
                .scrollIndicators(.visible, axes: .vertical)
                .viewModifier { view in
                    if #available(macOS 26, *) {
                        view.scrollEdgeEffectStyle(.soft, for: .all)
                    } else {
                        view
                    }
                }
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
            Button(role: .cancel) {} label: { Text("key.ok") }
        } message: {
            if let message = viewModel.message {
                Text(message)
            } else if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
        .alert("key.comments.success", isPresented: $viewModel.isOnModerationPresented) {
            Button(role: .cancel) {} label: { Text("key.ok") }
        } message: {
            if let message = viewModel.message {
                Text(message)
            }
        }
        .dialogSeverity(.automatic)
        .sheet(isPresented: $viewModel.isCommentPresented) {
            VStack(alignment: .center, spacing: 25) {
                if let comment = viewModel.comment {
                    ScrollView(.vertical) {
                        CommentView(comment: comment)
                            .equatable()
                            .environment(viewModel)
                    }
                    .scrollIndicators(.visible, axes: .vertical)
                } else {
                    ProgressView()
                }

                Button {
                    viewModel.isCommentPresented = false
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
        .sheet(item: $viewModel.reportComment) { comment in
            CommentReportSheetView(comment: comment)
        }
        .confirmationDialog("key.comment.delete.label", isPresented: Binding {
            viewModel.deleteComment != nil
        } set: {
            if !$0 {
                viewModel.deleteComment = nil
            }
        }) {
            if let comment = viewModel.deleteComment {
                Button {
                    viewModel.deleteComment(comment: comment)
                } label: {
                    Text("key.comment.delete.confirm")
                }
            }
        } message: {
            Text("key.comment.delete")
        }
        .background(.background)
        .navigationDestination(item: $viewModel.movieDestination) {
            DetailsView(movie: $0)
        }
    }
}

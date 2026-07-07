import Defaults
import SwiftUI

struct DetailsView: View {
    private let title: String?

    @State private var viewModel: DetailsViewModel

    init(movie: MovieSimple) {
        title = movie.name
        viewModel = DetailsViewModel(id: movie.movieId)
    }

    @State private var isBookmarksPresented = false
    @State private var isCreateBookmarkPresented = false
    @State private var isSchedulePresented = false

    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.mirror) private var mirror

    @State private var topSafeAreaInset: CGFloat = .zero

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let details = viewModel.state.data {
                    DetailsComponentView(
                        details: details,
                        trailerId: viewModel.trailerId,
                        topSafeAreaInset: topSafeAreaInset,
                        isSchedulePresented: $isSchedulePresented
                    )
                    .environment(viewModel)
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
            if let error = viewModel.state.error {
                ErrorStateView(error) {
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
        .navigationTitle(viewModel.state.data?.nameRussian ?? title ?? "")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    viewModel.load()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(viewModel.state.data == nil)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if let details = viewModel.state.data {
                    NavigationLink(value: Destinations.comments(details)) {
                        HStack(alignment: .center, spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right")

                            if let details = viewModel.state.data, details.commentsCount > 0 {
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
                    .disabled(viewModel.state.data == nil)
                }

                ShareLink(item: (!_mirror.isDefaultValue ? mirror : Const.redirectMirror).appending(path: viewModel.id, directoryHint: .notDirectory)) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.state.data == nil)
            }
        }
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.safeAreaInsets.top
        } action: { inset in
            topSafeAreaInset = inset
        }
        .onAppear {
            switch viewModel.state {
            case .data:
                break
            default:
                viewModel.load()
            }
        }
        .sheet(isPresented: $isBookmarksPresented) {
            BookmarksSheetView(id: viewModel.id, isCreateBookmarkPresented: $isCreateBookmarkPresented)
        }
        .sheet(isPresented: $isCreateBookmarkPresented) {
            CreateBookmarkSheetView()
        }
        .sheet(isPresented: $isSchedulePresented) {
            if let details = viewModel.state.data, let schedule = details.schedule, !schedule.isEmpty {
                ScheduleSheetView(schedule: schedule)
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
        .onChange(of: isCreateBookmarkPresented) {
            isBookmarksPresented = !isCreateBookmarkPresented
        }
        .background(.background)
        .navigationDestination(item: $viewModel.countryDestination) {
            ListView(country: $0)
        }
        .navigationDestination(item: $viewModel.genreDestination) {
            ListView(genre: $0)
        }
        .navigationDestination(item: $viewModel.personDestination) {
            PersonView(person: $0)
        }
        .navigationDestination(item: $viewModel.listDestination) {
            ListView(list: $0)
        }
        .navigationDestination(item: $viewModel.collectionDestination) {
            ListView(collection: $0)
        }
    }
}

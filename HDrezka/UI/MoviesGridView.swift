import SwiftUI

struct MoviesGridView<Card: View>: View {
    private let movies: [MovieSimple]?
    private let pagination: DataPaginationState
    private let padding: EdgeInsets
    private let loadMore: () -> Void
    private let card: (MovieSimple) -> Card

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: .infinity), spacing: 18, alignment: .topLeading),
    ]

    init(
        _ movies: [MovieSimple]?,
        pagination: DataPaginationState,
        padding: EdgeInsets = EdgeInsets(top: 18, leading: 36, bottom: 18, trailing: 36),
        loadMore: @escaping () -> Void,
        @ViewBuilder card: @escaping (MovieSimple) -> Card
    ) {
        self.movies = movies
        self.pagination = pagination
        self.padding = padding
        self.loadMore = loadMore
        self.card = card
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                if let movies, !movies.isEmpty {
                    ForEach(movies) { movie in
                        card(movie)
                    }
                }
            }
            .scrollTargetLayout()
            .padding(padding)

            if pagination == .loading {
                LoadingPaginationStateView()
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .onScrollNearEnd(of: movies, threshold: 12, isEnabled: pagination == .idle, perform: loadMore)
    }
}

extension MoviesGridView where Card == EquatableView<CardView> {
    init(_ movies: [MovieSimple]?, pagination: DataPaginationState, loadMore: @escaping () -> Void) {
        self.init(movies, pagination: pagination, loadMore: loadMore) { movie in
            CardView(movie: movie).equatable()
        }
    }
}

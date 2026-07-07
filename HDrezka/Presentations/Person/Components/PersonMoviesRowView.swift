import SwiftUI

struct PersonMoviesRowView: View {
    private let title: String
    private let movies: [MovieSimple]

    init(_ title: String, _ movies: [MovieSimple]) {
        self.title = title
        self.movies = movies
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 9) {
                Text(title).font(.title.bold())

                Spacer()

                if movies.count > 10 {
                    NavigationLink(value: Destinations.customList(movies, title)) {
                        HStack(alignment: .center) {
                            Text("key.see_all")
                                .font(.subheadline)
                                .foregroundStyle(Color.accentColor)

                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .buttonStyle(.accessoryBar)
                }
            }
            .padding(.horizontal, 36)

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 18) {
                    ForEach(movies.prefix(10)) { movie in
                        CardView(movie: movie, reservesSpace: true)
                            .equatable()
                            .frame(width: 150)
                    }
                }
                .padding(.horizontal, 36)
            }
            .scrollIndicators(.never)
        }
    }
}

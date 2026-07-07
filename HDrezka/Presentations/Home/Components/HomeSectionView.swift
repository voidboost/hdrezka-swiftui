import SwiftUI

struct HomeSectionView: View {
    private let category: Category

    init(category: Category) {
        self.category = category
    }

    var body: some View {
        Section {
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 18) {
                    ForEach(category.movies) { movie in
                        CardView(movie: movie, reservesSpace: true)
                            .equatable()
                            .frame(width: 150)
                    }
                }
                .padding(.horizontal, 36)
            }
            .scrollIndicators(.never)
        } header: {
            HStack(alignment: .center, spacing: 9) {
                Text(category.title).font(.system(.title, weight: .semibold))

                Spacer()

                NavigationLink(value: Destinations.category(category.category)) {
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
            .padding(.horizontal, 36)
        }
    }
}

extension HomeSectionView: Equatable {
    static func == (lhs: HomeSectionView, rhs: HomeSectionView) -> Bool {
        lhs.category.id == rhs.category.id
    }
}

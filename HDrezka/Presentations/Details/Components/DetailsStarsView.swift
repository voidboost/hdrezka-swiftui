import SwiftUI

struct DetailsStarsView: View {
    private let rating: CGFloat
    private let color: Color

    init(rating: Float, color: Color = .accentColor) {
        self.rating = CGFloat(rating)
        self.color = color
    }

    private var stars: some View {
        HStack(spacing: 0) {
            ForEach(0 ..< 5, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(.body, design: .rounded))
                    .aspectRatio(contentMode: .fit)
            }
        }
    }

    var body: some View {
        stars
            .overlay(alignment: .leading) {
                GeometryReader { geometry in
                    color.frame(width: (rating / 5.0) * geometry.size.width)
                }
                .mask(stars)
            }
            .foregroundStyle(.tertiary)
    }
}

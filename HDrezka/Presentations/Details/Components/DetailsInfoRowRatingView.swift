import Defaults
import SwiftUI

struct DetailsInfoRowRatingView: View {
    private let title: String
    private let rating: Float
    private let rated: Bool
    private let votes: String?

    @State private var hover: Float?
    @State private var vote: Bool = false

    @Default(.isLoggedIn) private var isLoggedIn

    @Environment(DetailsViewModel.self) private var viewModel

    init(_ title: String, _ rating: Float, _ rated: Bool, _ votes: String?) {
        self.title = title
        self.rating = rating
        self.rated = rated
        self.votes = votes
    }

    private var stars: some View {
        HStack(spacing: 0) {
            ForEach(0 ..< 10) { index in
                if !rated, isLoggedIn {
                    Button {
                        viewModel.rate(rating: index + 1)
                    } label: {
                        Image(systemName: "star.fill")
                            .font(.system(.body, design: .rounded))
                            .aspectRatio(contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .onHover { hover in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if hover {
                                self.hover = Float(index + 1)
                            } else {
                                self.hover = nil
                            }
                        }
                    }
                } else {
                    Image(systemName: "star.fill")
                        .font(.system(.body, design: .rounded))
                        .aspectRatio(contentMode: .fit)
                }
            }
        }
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.body)

            Spacer(minLength: 10)

            HStack(alignment: .center, spacing: 4) {
                stars
                    .background(alignment: .leading) {
                        GeometryReader { geometry in
                            (hover != nil ? Color.primary : Color.secondary)
                                .frame(width: (CGFloat(hover ?? rating) / 10.0) * geometry.size.width)
                        }
                        .mask(stars)
                    }
                    .foregroundStyle(.tertiary)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(verbatim: "\(rating)")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: Double(rating)))

                    if let votes, vote {
                        Text(verbatim: "(\(votes))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }
                }
                .viewModifier { view in
                    if votes != nil {
                        view.onHover { hover in
                            withAnimation(.easeInOut) {
                                vote = hover
                            }
                        }
                    } else {
                        view
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

import Kingfisher
import SwiftUI

struct CardView: View {
    private let movie: MovieSimple
    private let draggable: Bool
    private let reservesSpace: Bool

    init(movie: MovieSimple, draggable: Bool = false, reservesSpace: Bool = false) {
        self.movie = movie
        self.draggable = draggable
        self.reservesSpace = reservesSpace
    }

    var body: some View {
        NavigationLink(route: .details(movie)) {
            VStack(alignment: .leading, spacing: 6) {
                if let poster = movie.poster {
                    KFImage
                        .url(URL(string: poster))
                        .placeholder {
                            Color.gray.shimmering()
                        }
                        .resizable()
                        .loadTransition(.blurReplace(.downUp), animation: .bouncy)
                        .cancelOnDisappear(true)
                        .retry(NetworkRetryStrategy())
                        .imageFill(2 / 3)
                        .clipShape(.rect(cornerRadius: 6))
                        .overlay(alignment: .topTrailing) {
                            if let cat = movie.cat {
                                let icon = Text(Image(systemName: cat.icon))

                                Group {
                                    if let rating = cat.rating {
                                        Text("key.cat-\(cat.title)-\(Text(verbatim: "\(rating)").fontWeight(.medium))-\(icon)")
                                    } else {
                                        Text("key.cat-\(cat.title)-\(icon)")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.vertical, 3)
                                .padding(.horizontal, 6)
                                .background(cat.color, in: .rect(bottomLeadingRadius: 6, topTrailingRadius: 6))
                            }
                        }
                        .overlay(alignment: .bottomLeading) {
                            if let info = movie.info {
                                Text(info.title)
                                    .lineLimit(1)
                                    .font(.caption)
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 6)
                                    .background(.ultraThickMaterial, in: .rect(bottomLeadingRadius: 6, topTrailingRadius: 6))
                            }
                        }
                }

                if let name = movie.name, let details = movie.details {
                    ZStack(alignment: .topLeading) {
                        if reservesSpace {
                            VStack(alignment: .leading) {
                                Text(verbatim: " ")
                                    .font(.title3.weight(.semibold))
                                    .lineLimit(2, reservesSpace: true)

                                Text(verbatim: " ")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2, reservesSpace: true)
                            }
                            .hidden()
                        }

                        VStack(alignment: .leading) {
                            Text(name)
                                .font(.title3.weight(.semibold))
                                .lineLimit(2)

                            Text(details)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .contentShape(.rect(topLeadingRadius: 6, topTrailingRadius: 6))
            .viewModifier { view in
                if draggable {
                    view.draggable(movie)
                } else {
                    view
                }
            }
            .snowSurface(in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

extension CardView: Equatable {
    nonisolated static func == (lhs: CardView, rhs: CardView) -> Bool {
        return lhs.movie.id == rhs.movie.id
    }
}

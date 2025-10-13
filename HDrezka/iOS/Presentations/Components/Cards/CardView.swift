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
        NavigationLink(value: Destinations.details(movie)) {
            VStack(alignment: .leading, spacing: 6) {
                if let poster = movie.poster {
                    AsyncImage(url: URL(string: poster), transaction: .init(animation: .easeInOut)) { phase in
                        if let image = phase.image {
                            image.resizable()
                        } else {
                            Color.gray.shimmering()
                        }
                    }
                    .imageFill(2 / 3)
                    .overlay {
                        VStack {
                            if let cat = movie.cat {
                                HStack {
                                    Spacer()

                                    if let rating = cat.rating {
                                        let rating = Text(verbatim: "\(rating)").fontWeight(.medium)
                                        let icon = Text(Image(systemName: cat.icon))

                                        Text("key.cat-\(cat.title)-\(rating)-\(icon)")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                            .padding(.vertical, 3)
                                            .padding(.horizontal, 6)
                                            .background(cat.color)
                                            .clipShape(.rect(bottomLeadingRadius: 6))
                                    } else {
                                        let icon = Text(Image(systemName: cat.icon))

                                        Text("key.cat-\(cat.title)-\(icon)")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                            .padding(.vertical, 3)
                                            .padding(.horizontal, 6)
                                            .background(cat.color)
                                            .clipShape(.rect(bottomLeadingRadius: 6))
                                    }
                                }
                            }

                            Spacer()

                            if let info = movie.info {
                                HStack {
                                    Text(info.title)
                                        .lineLimit(1)
                                        .font(.caption)
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 6)
                                        .background(.ultraThickMaterial)
                                        .clipShape(.rect(topTrailingRadius: 6))

                                    Spacer()
                                }
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadius: 6))
                }

                if let name = movie.name, let details = movie.details {
                    if reservesSpace {
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading) {
                                Text(name)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.clear)
                                    .lineLimit(2, reservesSpace: true)

                                Text(details)
                                    .font(.subheadline)
                                    .foregroundStyle(.clear)
                                    .lineLimit(2, reservesSpace: true)
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
                    } else {
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
        }
        .buttonStyle(.plain)
    }
}

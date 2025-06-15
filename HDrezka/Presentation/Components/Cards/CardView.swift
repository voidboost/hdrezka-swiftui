import NukeUI
import SwiftUI

struct CardView: View {
    private let movie: MovieSimple
    private let draggable: Bool
    private let reservesSpace: Bool

    @EnvironmentObject private var appState: AppState

    init(movie: MovieSimple, draggable: Bool = false, reservesSpace: Bool = false) {
        self.movie = movie
        self.draggable = draggable
        self.reservesSpace = reservesSpace
    }

    var body: some View {
        Button {
            appState.path.append(.details(movie))
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                if let poster = movie.poster {
                    LazyImage(url: URL(string: poster), transaction: .init(animation: .easeInOut)) { state in
                        if let image = state.image {
                            image.resizable()
                        } else {
                            Color.gray.shimmering()
                        }
                    }
                    .onDisappear(.cancel)
                    .imageFill(2 / 3)
                    .overlay {
                        VStack {
                            if let cat = movie.cat {
                                HStack {
                                    Spacer()

                                    if let rating = cat.rating {
                                        (
                                            Text(verbatim: "\(cat.title) (") +
                                                Text(rating.description).fontWeight(.medium) +
                                                Text(verbatim: ") ") +
                                                Text(Image(systemName: cat.icon)),
                                        )
                                        .font(.system(size: 10))
                                        .textModifier { text in
                                            if #available(macOS 14, *) {
                                                text.foregroundStyle(.white)
                                            } else {
                                                text.foregroundColor(.white)
                                            }
                                        }
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 6)
                                        .background(cat.color)
                                        .clipShape(.rect(bottomLeadingRadius: 6))
                                    } else {
                                        (
                                            Text(verbatim: "\(cat.title) ") +
                                                Text(Image(systemName: cat.icon)),
                                        )
                                        .font(.system(size: 10))
                                        .textModifier { text in
                                            if #available(macOS 14, *) {
                                                text.foregroundStyle(.white)
                                            } else {
                                                text.foregroundColor(.white)
                                            }
                                        }
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
                                        .font(.system(size: 10))
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
                                    .font(.system(size: 15).weight(.semibold))
                                    .foregroundStyle(.clear)
                                    .lineLimit(2, reservesSpace: true)

                                Text(details)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.clear)
                                    .lineLimit(2, reservesSpace: true)
                            }

                            VStack(alignment: .leading) {
                                Text(name)
                                    .font(.system(size: 15).weight(.semibold))
                                    .lineLimit(2)

                                Text(details)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text(name)
                                .font(.system(size: 15).weight(.semibold))
                                .lineLimit(2)

                            Text(details)
                                .font(.system(size: 12))
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

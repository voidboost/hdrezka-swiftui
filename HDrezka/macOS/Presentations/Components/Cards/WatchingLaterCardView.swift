import SwiftUI

struct WatchingLaterCardView: View {
    private let movie: MovieWatchLater

    init(movie: MovieWatchLater) {
        self.movie = movie
    }

    @State private var innerHeight: CGFloat = 1
    @State private var outerHeight: CGFloat = 1

    var body: some View {
        NavigationLink(value: Destinations.details(MovieSimple(movieId: movie.watchLaterId, name: movie.name, poster: movie.cover))) {
            VStack(alignment: .leading, spacing: 6) {
                AsyncImage(url: URL(string: movie.cover), transaction: .init(animation: .easeInOut)) { phase in
                    if let image = phase.image {
                        image.resizable()
                    } else {
                        Color.gray.shimmering()
                    }
                }
                .imageFill(2 / 3)
                .overlay {
                    VStack(alignment: .leading) {
                        Spacer()

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                VStack(alignment: .leading) {
                                    if !movie.watchingInfo.isEmpty, let last = movie.watchingInfo.split(separator: "(", maxSplits: 1).last {
                                        Text(String(last).trim().removeLastCharacterIf(character: ")"))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(movie.buttonText != nil && !movie.watched ? Color.secondary : Color.primary)
                                            .lineLimit(1)
                                    }

                                    if !movie.watchingInfo.isEmpty, movie.watchingInfo.split(separator: "(", maxSplits: 1).count > 1, let first = movie.watchingInfo.split(separator: "(", maxSplits: 1).first {
                                        Text(String(first).trim())
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(movie.buttonText != nil && !movie.watched ? Color.secondary : Color.primary)
                                            .lineLimit(1)
                                    }
                                }

                                if let text = movie.buttonText, !text.isEmpty, !movie.watched {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(text.split(separator: " ", maxSplits: 2).dropLast().joined(separator: " ").firstLetterUppercased())
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.primary)

                                        if let last = text.split(separator: " ", maxSplits: 2).last {
                                            Text(last)
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                }
                            }
                            .padding(6)
                            .onGeometryChange(for: CGFloat.self) { geometry in
                                geometry.size.height
                            } action: { height in
                                innerHeight = height
                            }

                            Spacer()
                        }
                        .padding(.top, 36)
                        .onGeometryChange(for: CGFloat.self) { geometry in
                            geometry.size.height
                        } action: { height in
                            outerHeight = height
                        }
                        .background {
                            VStack {}
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.ultraThinMaterial)
                                .mask {
                                    LinearGradient(stops: [
                                        .init(color: .clear, location: ((outerHeight - innerHeight) / outerHeight) * 0.75),
                                        .init(color: .black, location: (outerHeight - innerHeight) / outerHeight),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom)
                                }
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 6))

                VStack(alignment: .leading) {
                    Text(movie.name)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)

                    Text(movie.details.trimmingCharacters(in: CharacterSet(charactersIn: "()")))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(movie.date.replacingOccurrences(of: "-", with: ".").firstLetterUppercased())
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(.rect(topLeadingRadius: 6, topTrailingRadius: 6))
        }
        .buttonStyle(.plain)
        .opacity(movie.watched ? 0.6 : 1)
        .disabled(movie.watchLaterId.removeMirror().components(separatedBy: "/").count(where: { !$0.isEmpty }) != 3)
    }
}

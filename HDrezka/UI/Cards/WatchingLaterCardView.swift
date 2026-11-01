import Kingfisher
import SwiftUI

struct WatchingLaterCardView: View {
    private let movie: MovieWatchLater

    init(movie: MovieWatchLater) {
        self.movie = movie
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !movie.watchingInfo.isEmpty {
                VStack(alignment: .leading) {
                    Text(movie.watchingInfo.substringAfter("(").substringBeforeLast(")").trim())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(movie.buttonText != nil && !movie.watched ? Color.secondary : Color.primary)
                        .lineLimit(1)

                    if movie.watchingInfo.contains("(") {
                        Text(movie.watchingInfo.substringBefore("(").trim())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(movie.buttonText != nil && !movie.watched ? Color.secondary : Color.primary)
                            .lineLimit(1)
                    }
                }
            }

            if let text = movie.buttonText, !text.isEmpty, !movie.watched {
                VStack(alignment: .leading, spacing: 0) {
                    Text(text.split(separator: " ", maxSplits: 2).dropLast().joined(separator: " ").firstLetterUppercased)
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
    }

    var body: some View {
        NavigationLink(route: .details(MovieSimple(movieId: movie.watchLaterId, name: movie.name, poster: movie.cover))) {
            VStack(alignment: .leading, spacing: 6) {
                KFImage
                    .url(URL(string: movie.cover))
                    .placeholder {
                        Color.gray.shimmering()
                    }
                    .resizable()
                    .loadTransition(.blurReplace(.downUp), animation: .bouncy)
                    .cancelOnDisappear(true)
                    .retry(NetworkRetryStrategy())
                    .imageFill(2 / 3)
                    .clipShape(.rect(cornerRadius: 6))
                    .overlay(alignment: .bottomLeading) {
                        UnevenRoundedRectangle(bottomLeadingRadius: 6, bottomTrailingRadius: 6)
                            .fill(.ultraThickMaterial)
                            .mask {
                                BottomFadeLayout {
                                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)

                                    Color.black

                                    info.hidden()
                                }
                            }
                    }
                    .overlay(alignment: .bottomLeading) {
                        info
                    }

                VStack(alignment: .leading) {
                    Text(movie.name)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)

                    Text(movie.details.trimmingCharacters(in: CharacterSet(charactersIn: "()")))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(movie.date.replacingOccurrences(of: "-", with: ".").firstLetterUppercased)
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(.rect(topLeadingRadius: 6, topTrailingRadius: 6))
            .snowSurface(in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .opacity(movie.watched ? 0.6 : 1)
        .disabled(movie.watchLaterId.id == nil)
    }
}

extension WatchingLaterCardView: Equatable {
    nonisolated static func == (lhs: WatchingLaterCardView, rhs: WatchingLaterCardView) -> Bool {
        lhs.movie.id == rhs.movie.id && lhs.movie.watched == rhs.movie.watched
    }
}

private struct BottomFadeLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews _: Subviews, cache _: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        guard subviews.count == 3 else { return }

        let content = subviews[2].sizeThatFits(ProposedViewSize(bounds.size))
        let top = max(bounds.height - content.height, 0)
        let fade = top * 0.25

        subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.minY + top - fade), proposal: ProposedViewSize(width: bounds.width, height: fade))
        subviews[1].place(at: CGPoint(x: bounds.minX, y: bounds.minY + top), proposal: ProposedViewSize(width: bounds.width, height: content.height))
        subviews[2].place(at: CGPoint(x: bounds.minX, y: bounds.minY + top), proposal: ProposedViewSize(content))
    }
}

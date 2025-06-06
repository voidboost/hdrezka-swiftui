import NukeUI
import SwiftUI

struct WatchingLaterCardView: View {
    private let movie: MovieWatchLater

    @EnvironmentObject private var appState: AppState

    init(movie: MovieWatchLater) {
        self.movie = movie
    }

    @State private var innerHeight: CGFloat = 1
    @State private var outerHeight: CGFloat = 1

    var body: some View {
        Button {
            appState.path.append(.details(MovieSimple(movieId: movie.watchLaterId, name: movie.name, poster: movie.cover)))
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                LazyImage(url: URL(string: movie.cover), transaction: .init(animation: .easeInOut)) { state in
                    if let image = state.image {
                        image.resizable()
                            .transition(
                                .asymmetric(
                                    insertion: .wipe(blurRadius: 10),
                                    removal: .wipe(reversed: true, blurRadius: 10)
                                )
                            )
                    } else {
                        Color.gray
                            .shimmering()
                            .transition(
                                .asymmetric(
                                    insertion: .wipe(blurRadius: 10),
                                    removal: .wipe(reversed: true, blurRadius: 10)
                                )
                            )
                    }
                }
                .onDisappear(.cancel)
                .imageFill(2 / 3)
                .overlay {
                    VStack(alignment: .leading) {
                        Spacer()

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                VStack(alignment: .leading) {
                                    if !movie.watchingInfo.isEmpty, let last = movie.watchingInfo.split(separator: "(", maxSplits: 1).last {
                                        Text(last.trimmingCharacters(in: .whitespacesAndNewlines).removeLastCharacterIf(character: ")"))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(movie.buttonText != nil && !movie.watched ? Color.secondary : .primary)
                                            .lineLimit(1)
                                    }

                                    if !movie.watchingInfo.isEmpty, movie.watchingInfo.split(separator: "(", maxSplits: 1).count > 1, let first = movie.watchingInfo.split(separator: "(", maxSplits: 1).first {
                                        Text(first.trimmingCharacters(in: .whitespacesAndNewlines))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(movie.buttonText != nil && !movie.watched ? Color.secondary : .primary)
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
                                self.innerHeight = height
                            }

                            Spacer()
                        }
                        .padding(.top, 36)
                        .onGeometryChange(for: CGFloat.self) { geometry in
                            geometry.size.height
                        } action: { height in
                            self.outerHeight = height
                        }
                        .background {
                            VStack {}
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.ultraThinMaterial)
                                .mask {
                                    LinearGradient(stops: [
                                        .init(color: .clear, location: ((outerHeight - innerHeight) / outerHeight) * 0.75),
                                        .init(color: .black, location: (outerHeight - innerHeight) / outerHeight)
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
                        .font(.system(size: 15).weight(.semibold))
                        .lineLimit(2)

                    Text(movie.details.trimmingCharacters(in: CharacterSet(charactersIn: "()")))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(movie.date.replacingOccurrences(of: "-", with: ".").firstLetterUppercased())
                        .font(.system(size: 12))
                        .foregroundStyle(.accent)
                }
            }
            .contentShape(.rect(topLeadingRadius: 6, topTrailingRadius: 6))
        }
        .buttonStyle(.plain)
        .opacity(movie.watched ? 0.6 : 1)
        .disabled(movie.watchLaterId.removeMirror().components(separatedBy: "/").filter { !$0.isEmpty }.count != 3)
    }
}

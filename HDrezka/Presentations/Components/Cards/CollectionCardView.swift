import Kingfisher
import SwiftUI

struct CollectionCardView: View {
    private let collection: MoviesCollection

    init(collection: MoviesCollection) {
        self.collection = collection
    }

    var body: some View {
        NavigationLink(value: Destinations.collection(collection)) {
            VStack(alignment: .center, spacing: 6) {
                if let poster = collection.poster {
                    KFImage
                        .url(URL(string: poster))
                        .placeholder {
                            Color.gray.shimmering()
                        }
                        .resizable()
                        .loadTransition(.blurReplace, animation: .easeInOut)
                        .cancelOnDisappear(true)
                        .retry(NetworkRetryStrategy())
                        .imageFill(5 / 3)
                        .clipShape(.rect(cornerRadius: 6))
                        .overlay(alignment: .topTrailing) {
                            if let count = collection.count {
                                Text(verbatim: "\(count)")
                                    .lineLimit(1)
                                    .font(.caption)
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 6)
                                    .background(.ultraThickMaterial, in: .rect(bottomLeadingRadius: 6, topTrailingRadius: 6))
                            }
                        }
                }

                Text(collection.name)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .contentShape(.rect(topLeadingRadius: 6, topTrailingRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

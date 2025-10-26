import Kingfisher
import SwiftUI

struct CollectionCardView: View {
    private let collection: MoviesCollection

    init(collection: MoviesCollection) {
        self.collection = collection
    }

    var body: some View {
        NavigationLink(value: Destinations.collection(collection)) {
            VStack {
                if let poster = collection.poster {
                    KFImage
                        .url(URL(string: poster))
                        .placeholder {
                            Color.gray.shimmering()
                        }
                        .resizable()
                        .loadTransition(.blurReplace, animation: .easeInOut)
                        .cancelOnDisappear(true)
                        .imageFill(5 / 3)
                        .clipShape(.rect(cornerRadius: 6))
                        .contentShape(.rect(cornerRadius: 6))
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
                        .overlay(alignment: .bottom) {
                            Text(collection.name)
                                .font(.title3.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .padding(9)
                                .frame(maxWidth: .infinity)
                                .background(.ultraThickMaterial, in: .rect(bottomLeadingRadius: 6, bottomTrailingRadius: 6))
                        }
                        .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

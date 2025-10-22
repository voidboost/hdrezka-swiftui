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
                    AsyncImage(url: URL(string: poster), transaction: .init(animation: .easeInOut)) { phase in
                        if let image = phase.image {
                            image.resizable()
                        } else {
                            Color.gray.shimmering()
                        }
                    }
                    .imageFill(5 / 3)
                    .clipShape(.rect(cornerRadius: 6))
                    .contentShape(.rect(cornerRadius: 6))
                    .overlay(.ultraThickMaterial.opacity(0.75), in: .rect(cornerRadius: 6))
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
                    .overlay(alignment: .center) {
                        Text(collection.name)
                            .font(.title3.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(9)
                    }
                    .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

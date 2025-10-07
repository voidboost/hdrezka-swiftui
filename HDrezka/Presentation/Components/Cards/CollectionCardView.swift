import SwiftUI

struct CollectionCardView: View {
    private let collection: MoviesCollection

    @Environment(AppState.self) private var appState

    init(collection: MoviesCollection) {
        self.collection = collection
    }

    var body: some View {
        Button {
            appState.append(.collection(collection))
        } label: {
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
                    .overlay {
                        ZStack(alignment: .center) {
                            VStack {}
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.ultraThickMaterial.opacity(0.75))

                            if let count = collection.count {
                                VStack {
                                    HStack {
                                        Spacer()

                                        Text(verbatim: "\(count)")
                                            .lineLimit(1)
                                            .font(.system(size: 10))
                                            .padding(.vertical, 3)
                                            .padding(.horizontal, 6)
                                            .background(.ultraThickMaterial)
                                            .clipShape(.rect(bottomLeadingRadius: 6))
                                    }

                                    Spacer()
                                }
                            }

                            Text(collection.name)
                                .font(.system(size: 15).weight(.semibold))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .padding(9)
                        }
                    }
                    .clipShape(.rect(cornerRadius: 6))
                    .contentShape(.rect(cornerRadius: 6))
                    .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

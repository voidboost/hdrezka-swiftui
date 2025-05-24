import NukeUI
import SwiftUI

struct CollectionCardView: View {
    private let collection: MoviesCollection

    @EnvironmentObject private var appState: AppState

    init(collection: MoviesCollection) {
        self.collection = collection
    }

    var body: some View {
        Button {
            appState.path.append(.collection(collection))
        } label: {
            VStack {
                if let poster = collection.poster {
                    LazyImage(url: URL(string: poster), transaction: .init(animation: .easeInOut)) { state in
                        if let image = state.image {
                            image.resizable()
                                .transition(
                                    .asymmetric(
                                        insertion: .wipe(blurRadius: 10),
                                        removal: .wipe(reversed: true, blurRadius: 10)
                                    )
                                )
                        } else {
                            Rectangle()
                                .fill(.gray)
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

                                        HStack {
                                            Text(count.description)
                                                .lineLimit(1)
                                        }
                                        .font(.system(size: 10))
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 6)
                                        .background(.ultraThickMaterial)
                                        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 6))
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
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.tertiary, lineWidth: 1)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

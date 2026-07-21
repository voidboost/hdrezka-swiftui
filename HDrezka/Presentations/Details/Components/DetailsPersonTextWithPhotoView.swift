import Kingfisher
import SwiftUI

struct DetailsPersonTextWithPhotoView: View {
    private let person: PersonSimple

    init(person: PersonSimple) {
        self.person = person
    }

    @State private var show: Bool = false

    var body: some View {
        Text(person.name)
            .font(.body)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .onHover {
                show = $0
            }
            .popover(isPresented: $show) {
                KFImage
                    .url(URL(string: person.photo))
                    .placeholder {
                        Color.gray.shimmering()
                    }
                    .resizable()
                    .loadTransition(.blurReplace(.downUp), animation: .bouncy)
                    .removeBackground()
                    .cancelOnDisappear(true)
                    .retry(NetworkRetryStrategy())
                    .imageFill(2 / 3)
                    .frame(width: 64, height: 64)
                    .background(.quinary)
                    .clipShape(.circle)
                    .padding(4)
                    .overlay(.tertiary.opacity(0.2), in: .circle.stroke(lineWidth: 1))
                    .padding(4)
            }
    }
}

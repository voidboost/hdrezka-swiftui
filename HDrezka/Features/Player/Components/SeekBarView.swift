import AVKit
import ComposableArchitecture
import SwiftUI

struct SeekBarView: View {
    @Environment(StoreOf<PlayerFeature>.self) private var store

    var body: some View {
        SliderWithTextView(value: Binding {
            store.currentTime
        } set: { time in
            store.send(.seek(time))
        }, inRange: 0 ... store.duration, buffers: store.loadedTimeRanges, activeFillColor: .primary, fillColor: .primary.opacity(0.7), emptyColor: .primary.opacity(0.3), height: 8, thumbnails: store.thumbnails) { _ in }
            .frame(height: 25)
            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
    }
}

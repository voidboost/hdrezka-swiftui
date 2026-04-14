import AVKit
import SwiftUI

struct AirPlayButtonView: NSViewRepresentable {
    private let player: AVPlayer
    private let onPress: (Bool) -> Void

    init(player: AVPlayer, onPress: @escaping (Bool) -> Void) {
        self.player = player
        self.onPress = onPress
    }

    func makeNSView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()

        routePickerView.player = player
        routePickerView.isRoutePickerButtonBordered = false
        routePickerView.delegate = context.coordinator

        return routePickerView
    }

    func updateNSView(_: AVRoutePickerView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPress: onPress)
    }

    class Coordinator: NSObject, AVRoutePickerViewDelegate {
        private let onPress: (Bool) -> Void

        init(onPress: @escaping (Bool) -> Void) {
            self.onPress = onPress
        }

        func routePickerViewWillBeginPresentingRoutes(_: AVRoutePickerView) {
            onPress(true)
        }

        func routePickerViewDidEndPresentingRoutes(_: AVRoutePickerView) {
            onPress(false)
        }
    }
}

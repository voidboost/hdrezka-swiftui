import Combine
import SwiftUI

struct OrientationView<Portrait: View, Landscape: View>: View {
    @State private var orientation: UIDeviceOrientation?
    @State private var subscriptions: Set<AnyCancellable> = []

    @Namespace private var animation

    private let portrait: (Namespace.ID) -> Portrait
    private let landscape: (Namespace.ID) -> Landscape

    init(
        @ViewBuilder portrait: @escaping (Namespace.ID) -> Portrait,
        @ViewBuilder landscape: @escaping (Namespace.ID) -> Landscape,
    ) {
        self.portrait = portrait
        self.landscape = landscape
    }

    var body: some View {
        Group {
            if let orientation, orientation.isLandscape {
                landscape(animation)
            } else {
                portrait(animation)
            }
        }
        .onAppear {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()

            orientation = UIDevice.current.orientation

            NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
                .compactMap { _ in UIDevice.current.orientation }
                .filter(\.isValidInterfaceOrientation)
                .receive(on: DispatchQueue.main)
                .sink { orientation in
                    withAnimation(.easeInOut) {
                        self.orientation = orientation
                    }
                }
                .store(in: &subscriptions)
        }
        .onDisappear {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()

            subscriptions.flush()
        }
    }
}

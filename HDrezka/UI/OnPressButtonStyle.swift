import SwiftUI

struct OnPressButtonStyle: ButtonStyle {
    private let onPress: (Bool) -> Void

    init(onPress: @escaping (Bool) -> Void) {
        self.onPress = onPress
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) {
                onPress(configuration.isPressed)
            }
    }
}

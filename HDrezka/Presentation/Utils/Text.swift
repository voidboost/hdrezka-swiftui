import SwiftUI

extension Text {
    func textModifier(
        body: (_ content: Self) -> Text
    ) -> Text {
        body(self)
    }
}

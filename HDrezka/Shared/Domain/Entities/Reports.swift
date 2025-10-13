import SwiftUI

enum Reports: LocalizedStringKey, CaseIterable, Identifiable {
    case obscene = "key.report.obscene"
    case spoiler = "key.report.spoiler"
    case insulting = "key.report.insulting"
    case flood = "key.report.flood"
    case other = "key.report.other"

    var id: Reports { self }
}

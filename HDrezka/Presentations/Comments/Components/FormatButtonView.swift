import SwiftUI

struct FormatButtonView: View {
    @Binding private var feedback: String
    @Binding private var selection: TextSelection?
    private let prefix: String
    private let suffix: String
    private let icon: String?

    init(
        feedback: Binding<String>,
        selection: Binding<TextSelection?>,
        prefix: String,
        suffix: String,
        icon: String? = nil
    ) {
        _feedback = feedback
        _selection = selection
        self.prefix = prefix
        self.suffix = suffix
        self.icon = icon
    }

    var body: some View {
        Button {
            switch selection?.indices {
            case let .selection(range):
                let lowerOffset = range.lowerBound.utf16Offset(in: feedback)
                let upperOffset = range.upperBound.utf16Offset(in: feedback)

                if let lowerIndex = feedback.utf16.index(feedback.utf16.startIndex, offsetBy: lowerOffset).samePosition(in: feedback),
                   let upperIndex = feedback.utf16.index(feedback.utf16.startIndex, offsetBy: upperOffset).samePosition(in: feedback)
                {
                    feedback.insert(contentsOf: suffix, at: upperIndex)
                    feedback.insert(contentsOf: prefix, at: lowerIndex)
                }

                let offset = prefix.utf16.count
                let newLowerOffset = lowerOffset + offset
                let newUpperOffset = upperOffset + offset

                if let lowerIndex = feedback.utf16.index(feedback.utf16.startIndex, offsetBy: newLowerOffset).samePosition(in: feedback),
                   let upperIndex = feedback.utf16.index(feedback.utf16.startIndex, offsetBy: newUpperOffset).samePosition(in: feedback)
                {
                    selection = TextSelection(range: lowerIndex ..< upperIndex)
                } else {
                    selection = nil
                }
            case let .multiSelection(rangeSet):
                let sortedRanges = rangeSet.ranges
                    .map { $0.lowerBound.utf16Offset(in: feedback) ..< $0.upperBound.utf16Offset(in: feedback) }
                    .sorted(by: { $0.lowerBound > $1.lowerBound })

                for range in sortedRanges {
                    if let lowerIndex = feedback.utf16.index(feedback.utf16.startIndex, offsetBy: range.lowerBound).samePosition(in: feedback),
                       let upperIndex = feedback.utf16.index(feedback.utf16.startIndex, offsetBy: range.upperBound).samePosition(in: feedback)
                    {
                        feedback.insert(contentsOf: suffix, at: upperIndex)
                        feedback.insert(contentsOf: prefix, at: lowerIndex)
                    }
                }

                let updatedRanges = sortedRanges.indexed().compactMap { index, range in
                    let offset = prefix.utf16.count + (prefix.utf16.count + suffix.utf16.count) * (sortedRanges.count - index - 1)
                    let newLowerOffset = range.lowerBound + offset
                    let newUpperOffset = range.upperBound + offset

                    if let lowerIndex = feedback.utf16.index(feedback.utf16.startIndex, offsetBy: newLowerOffset).samePosition(in: feedback),
                       let upperIndex = feedback.utf16.index(feedback.utf16.startIndex, offsetBy: newUpperOffset).samePosition(in: feedback)
                    {
                        return lowerIndex ..< upperIndex
                    } else {
                        return nil
                    }
                }

                selection = TextSelection(ranges: .init(updatedRanges))
            default:
                feedback.append(prefix + suffix)

                let offset = -suffix.utf16.count

                if let index = feedback.utf16.index(feedback.utf16.endIndex, offsetBy: offset).samePosition(in: feedback) {
                    selection = TextSelection(insertionPoint: index)
                }
            }
        } label: {
            if let icon {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(height: 28)
                    .padding(.horizontal, 16)
                    .contentShape(.capsule)
                    .background(.tertiary.opacity(0.05), in: .capsule)
                    .overlay(.tertiary.opacity(0.2), in: .capsule.stroke(lineWidth: 1))
            } else {
                Text("Spoiler!".uppercased())
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .frame(height: 28)
                    .padding(.horizontal, 16)
                    .contentShape(.capsule)
                    .background(.tertiary.opacity(0.05), in: .capsule)
                    .overlay(.tertiary.opacity(0.2), in: .capsule.stroke(lineWidth: 1))
            }
        }
        .buttonStyle(.plain)
    }
}

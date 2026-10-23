import ComposableArchitecture
import FirebaseAnalytics
import SwiftUI

struct CommentReportSheetView: View {
    @Bindable var store: StoreOf<CommentReportFeature>

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch store.status {
            case .data:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)

                        Text("key.report.label")
                            .font(.largeTitle.weight(.semibold))
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        ForEach(Reports.allCases) { report in
                            RadioButton(tag: report, selection: $store.report, message: $store.message, label: report.rawValue)
                        }
                    }

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            store.send(.submit, animation: .easeInOut)
                        } label: {
                            Text("key.report")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .contentShape(.rect(cornerRadius: 6))
                                .background(store.canSubmit ? Color.accentColor : Color.secondary, in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(!store.canSubmit)
                        .animation(.easeInOut, value: store.canSubmit)

                        Button {
                            dismiss()
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .contentShape(.rect(cornerRadius: 6))
                                .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .loading:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)

                        Text("key.report.enter")
                            .font(.largeTitle.weight(.semibold))

                        Text("key.request.wait")
                            .font(.title3)
                            .lineLimit(1, reservesSpace: true)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            store.send(.cancelRequest, animation: .easeInOut)
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .error:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)

                        Text("key.ops")
                            .font(.largeTitle.weight(.semibold))

                        Text("key.report.error")
                            .font(.title3)
                            .lineLimit(1, reservesSpace: true)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            store.send(.retry, animation: .easeInOut)
                        } label: {
                            Text("key.retry")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .contentShape(.rect(cornerRadius: 6))
                                .background(Color.accentColor, in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .contentShape(.rect(cornerRadius: 6))
                                .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6)).background(Color.accentColor, in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 35)
        .padding(.top, 35)
        .padding(.bottom, 25)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 520)
        .analyticsScreen(name: "comment_report_sheet", class: "CommentReportSheetView")
    }

    private struct RadioButton: View {
        @Binding private var isSelected: Bool
        @Binding private var message: String
        private let tag: Reports
        private let label: LocalizedStringKey

        @FocusState private var focused: Bool

        init(tag: Reports, selection: Binding<Reports?>, message: Binding<String>, label: LocalizedStringKey) {
            _isSelected = Binding(
                get: { selection.wrappedValue == tag },
                set: { _ in selection.wrappedValue = tag }
            )
            _message = message
            self.tag = tag
            self.label = label
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center, spacing: 0) {
                    Text(label)
                        .font(.title3)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)
                }

                if isSelected, tag == .other {
                    TextField("key.message", text: $message, prompt: Text(String(localized: "key.message.more")))
                        .textFieldStyle(.plain)
                        .font(.body)
                        .focused($focused)
                }
            }
            .padding(10)
            .contentShape(.rect(cornerRadius: 6))
            .clipShape(.rect(cornerRadius: 6))
            .overlay(isSelected ? Color.accentColor : Color.secondary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
            .onTapGesture { isSelected = true }
            .animation(.easeInOut, value: isSelected)
            .onChange(of: isSelected) {
                if isSelected, tag == .other {
                    focused = true
                } else {
                    focused = false
                }
            }
        }
    }
}

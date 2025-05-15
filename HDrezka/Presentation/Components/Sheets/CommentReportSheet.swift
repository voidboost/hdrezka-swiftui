import Combine
import FactoryKit
import SwiftUI

struct CommentReportSheet: View {
    private let comment: Comment

    init(comment: Comment) {
        self.comment = comment
    }

    @Injected(\.reportCommentUseCase) private var reportCommentUseCase

    @State private var subscriptions: Set<AnyCancellable> = []

    @Environment(\.dismiss) private var dismiss

    @State private var state: EmptyState = .data

    @State private var report: Reports?
    @State private var message: String = ""

    var body: some View {
        Group {
            switch state {
            case .data:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.accent)

                        Text("key.report.label")
                            .font(.largeTitle.weight(.semibold))
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        ForEach(Reports.allCases) { report in
                            RadioButton(tag: report, selection: $report, message: $message, label: report.rawValue)
                        }
                    }

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            withAnimation(.easeInOut) {
                                state = .loading
                            }

                            let issue = switch report {
                            case .obscene:
                                1
                            case .spoiler:
                                4
                            case .insulting:
                                2
                            case .flood:
                                3
                            case .other:
                                0
                            default:
                                0
                            }

                            reportCommentUseCase(id: comment.commentId, issue: issue, text: issue == 0 ? message : "")
                                .receive(on: DispatchQueue.main)
                                .sink { completion in
                                    guard case let .failure(error) = completion else { return }

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation(.easeInOut) {
                                            state = .error(error as NSError)
                                        }
                                    }
                                } receiveValue: { success in
                                    if success {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            dismiss()
                                        }
                                    } else {
                                        withAnimation(.easeInOut) {
                                            state = .error(NSError())
                                        }
                                    }
                                }
                                .store(in: &subscriptions)
                        } label: {
                            Text("key.report")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .background((report != nil && report != .other) || (report == .other && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? .accent : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(report == nil || (report == .other && message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                        .animation(.easeInOut, value: (report != nil && report != .other) || (report == .other && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))

                        Button {
                            dismiss()
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .background(.quinary.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .loading:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.accent)

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
                            subscriptions.forEach { $0.cancel() }
                            subscriptions.removeAll()

                            withAnimation(.easeInOut) {
                                state = .data
                            }
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .background {
                                    RoundedRectangle(cornerRadius: 6)
                                        .foregroundStyle(.quinary.opacity(0.5))
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .error:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.accent)

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
                            withAnimation(.easeInOut) {
                                state = .data
                            }
                        } label: {
                            Text("key.retry")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .background(.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .background(.quinary.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
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
    }

    private struct RadioButton: View {
        @Binding private var isSelected: Bool
        @Binding private var message: String
        private let tag: Reports
        private let label: LocalizedStringKey

        @FocusState private var focused: Bool

        init(tag: Reports, selection: Binding<Reports?>, message: Binding<String>, label: LocalizedStringKey) {
            self._isSelected = Binding(
                get: { selection.wrappedValue == tag },
                set: { _ in selection.wrappedValue = tag }
            )
            self._message = message
            self.tag = tag
            self.label = label
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .center, spacing: 0) {
                    Text(label)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)
                }

                if isSelected, tag == .other {
                    TextField("key.message", text: $message, prompt: Text(String(localized: "key.message.more")))
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($focused)
                }
            }
            .padding(10)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? .accent : .secondary, lineWidth: 1)
            }
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

    private enum Reports: LocalizedStringKey, CaseIterable, Identifiable {
        case obscene = "key.report.obscene"
        case spoiler = "key.report.spoiler"
        case insulting = "key.report.insulting"
        case flood = "key.report.flood"
        case other = "key.report.other"

        var id: Reports { self }
    }
}

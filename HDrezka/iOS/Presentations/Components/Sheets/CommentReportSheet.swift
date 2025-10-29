import Combine
import FactoryKit
import FirebaseAnalytics
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
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)

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
                                    guard case .failure = completion else { return }

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation(.easeInOut) {
                                            state = .error
                                        }
                                    }
                                } receiveValue: { success in
                                    if success {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            dismiss()
                                        }
                                    } else {
                                        withAnimation(.easeInOut) {
                                            state = .error
                                        }
                                    }
                                }
                                .store(in: &subscriptions)
                        } label: {
                            Text("key.report")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .contentShape(.rect(cornerRadius: 6))
                                .background((report != nil && report != .other) || (report == .other && !message.trim().isEmpty) ? Color.accentColor : Color.secondary, in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(report == nil || (report == .other && message.trim().isEmpty))
                        .animation(.easeInOut, value: (report != nil && report != .other) || (report == .other && !message.trim().isEmpty))

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
                            subscriptions.flush()

                            withAnimation(.easeInOut) {
                                state = .data
                            }
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
                            withAnimation(.easeInOut) {
                                state = .data
                            }
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
        .analyticsScreen(name: "comment_report_sheet", class: "CommentReportSheetView", extraParameters: comment.dictionary)
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
                set: { _ in selection.wrappedValue = tag },
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

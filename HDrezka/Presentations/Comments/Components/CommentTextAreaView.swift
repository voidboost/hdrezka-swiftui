import Defaults
import SwiftUI

struct CommentTextAreaView: View {
    @State private var feedback: String = ""
    @State private var name: String = ""
    @State private var selection: TextSelection?

    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.allowedComments) private var allowedComments

    @Environment(AppState.self) private var appState
    @Environment(CommentsViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                FormatButtonView(feedback: $feedback, selection: $selection, prefix: "[b]", suffix: "[/b]", icon: "bold")

                FormatButtonView(feedback: $feedback, selection: $selection, prefix: "[i]", suffix: "[/i]", icon: "italic")

                FormatButtonView(feedback: $feedback, selection: $selection, prefix: "[u]", suffix: "[/u]", icon: "underline")

                FormatButtonView(feedback: $feedback, selection: $selection, prefix: "[s]", suffix: "[/s]", icon: "strikethrough")

                FormatButtonView(feedback: $feedback, selection: $selection, prefix: "[spoiler]", suffix: "[/spoiler]")

                Spacer(minLength: 0)

                if !isLoggedIn {
                    TextField("key.name", text: $name, prompt: Text(String(localized: "key.name.full").lowercased()))
                        .textFieldStyle(.plain)
                        .font(.body)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .onChange(of: name) {
                            if name.count > 60 {
                                name = String(name.prefix(60))
                            }
                        }
                }

                Button {
                    viewModel.sendComment(name: isLoggedIn ? nil : name, text: feedback)

                    name = ""
                    feedback = ""
                } label: {
                    Text("key.send")
                        .font(.system(.title3, weight: .bold))
                        .frame(height: 28)
                        .padding(.horizontal, 16)
                        .contentShape(.capsule)
                        .background(.tertiary.opacity(0.05), in: .capsule)
                        .overlay(.tertiary.opacity(0.2), in: .capsule.stroke(lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(feedback.trim().isEmpty || (!isLoggedIn && name.trim().isEmpty) || !allowedComments)
                .animation(.easeInOut, value: feedback.trim().isEmpty || (!isLoggedIn && name.trim().isEmpty) || !allowedComments)
            }

            TextField("key.comments", text: $feedback, selection: $selection, prompt: Text(String(localized: "key.comments.placeholder").lowercased()))
                .textFieldStyle(.plain)
                .textSelectionAffinity(.automatic)
        }
        .padding(12)
        .overlay(.tertiary.opacity(0.2), in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
        .onChange(of: feedback) {
            if !allowedComments, !feedback.trim().isEmpty {
                appState.commentsRulesPresented = true
            }
        }
    }
}

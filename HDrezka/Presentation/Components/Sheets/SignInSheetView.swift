import Combine
import Defaults
import FactoryKit
import SwiftUI

struct SignInSheetView: View {
    @Injected(\.signInUseCase) private var signInUseCase

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var appState: AppState

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var state: EmptyState = .data

    @State private var showPassword: Bool = false
    @State private var passwordIsEmpty: Bool = true

    private enum FocusedField {
        case username, password
    }

    @FocusState private var focusedField: FocusedField?

    @State private var subscriptions: Set<AnyCancellable> = []

    var body: some View {
        Group {
            switch state {
            case .data:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.accent)

                        Text("key.sign_in.label")
                            .font(.largeTitle.weight(.semibold))

                        Text("key.sign_in.description")
                            .font(.title3)
                            .lineLimit(2, reservesSpace: true)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        VStack(spacing: 2.5) {
                            HStack(alignment: .center, spacing: 8) {
                                Text("key.username")

                                TextField("key.username", text: $username, prompt: Text(String(localized: "key.username.full").lowercased()))
                                    .textFieldStyle(.plain)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .username)
                                    .customOnChange(of: username) {
                                        let newValue = String(username.unicodeScalars.filter { CharacterSet.whitespacesAndNewlines.inverted.contains($0) })
                                        if newValue != username {
                                            username = newValue
                                        }
                                    }
                                    .onSubmit {
                                        focusedField = .password
                                    }
                            }
                            .padding(.vertical, 10)

                            Divider()

                            HStack(alignment: .center, spacing: 8) {
                                Text("key.password")

                                if showPassword {
                                    TextField("key.password", text: $password, prompt: Text(String(localized: "key.password").lowercased()))
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .password)
                                        .customOnChange(of: password) {
                                            let newValue = String(password.unicodeScalars.filter { CharacterSet.whitespacesAndNewlines.inverted.contains($0) })
                                            if newValue != password {
                                                password = newValue
                                            } else {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    passwordIsEmpty = newValue.isEmpty
                                                }
                                            }
                                        }
                                        .onSubmit {
                                            if !username.isEmpty, !password.isEmpty {
                                                load()
                                            }
                                        }
                                } else {
                                    SecureField("key.password", text: $password, prompt: Text(String(localized: "key.password").lowercased()))
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .password)
                                        .customOnChange(of: password) {
                                            let newValue = String(password.unicodeScalars.filter { CharacterSet.whitespacesAndNewlines.inverted.contains($0) })
                                            if newValue != password {
                                                password = newValue
                                            } else {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    passwordIsEmpty = newValue.isEmpty
                                                }
                                            }
                                        }
                                        .onSubmit {
                                            if !username.isEmpty, !password.isEmpty {
                                                load()
                                            }
                                        }
                                }

                                if !passwordIsEmpty {
                                    Image(systemName: "eye")
                                        .foregroundStyle(.accent.opacity(showPassword ? 0.5 : 1))
                                        .simultaneousGesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { _ in
                                                    withAnimation(.easeInOut(duration: 0.15)) {
                                                        showPassword = true
                                                    }
                                                }
                                                .onEnded { _ in
                                                    withAnimation(.easeInOut(duration: 0.15)) {
                                                        showPassword = false
                                                    }

                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                        focusedField = .password
                                                    }
                                                }
                                        )
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(.quinary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.tertiary, lineWidth: 1)
                        }

                        Button {
                            dismiss()

                            appState.isRestorePresented = true
                        } label: {
                            Text("key.password.lost")
                                .font(.caption)
                                .foregroundStyle(.accent)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            load()
                        } label: {
                            Text("key.sign_in")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .background(!username.isEmpty && !password.isEmpty ? .accent : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(username.isEmpty || password.isEmpty)
                        .animation(.easeInOut, value: !username.isEmpty && !password.isEmpty)

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

                    HStack(alignment: .center, spacing: 8) {
                        Text("key.sign_in.sign_up.q").font(.caption)

                        Button {
                            dismiss()

                            appState.isSignUpPresented = true
                        } label: {
                            Text(verbatim: "\(String(localized: "key.register"))!")
                                .font(.caption)
                                .foregroundStyle(.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .task {
                    focusedField = .username
                }
            case .loading:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.accent)

                        Text("key.sign_in.enter")
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
                                .background(.quinary.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .error:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.accent)

                        Text("key.ops")
                            .font(.largeTitle.weight(.semibold))

                        Text("key.sign_in.error")
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

    private func load() {
        withAnimation(.easeInOut) {
            state = .loading
        }

        signInUseCase(login: username, password: password)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut) {
                        state = .error(error as NSError)
                    }
                }
            } receiveValue: { success in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if success {
                        dismiss()
                    } else {
                        withAnimation(.easeInOut) {
                            state = .error(NSError())
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }
}

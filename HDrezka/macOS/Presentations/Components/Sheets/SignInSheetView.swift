import Combine
import Defaults
import FactoryKit
import FirebaseAnalytics
import SwiftUI

struct SignInSheetView: View {
    @Injected(\.signInUseCase) private var signInUseCase

    @Environment(\.dismiss) private var dismiss

    @Environment(AppState.self) private var appState

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
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)

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
                                        .onChange(of: password) {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                passwordIsEmpty = password.isEmpty
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
                                        .onChange(of: password) {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                passwordIsEmpty = password.isEmpty
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
                                        .foregroundStyle(Color.accentColor.opacity(showPassword ? 0.5 : 1))
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
                                                    } completion: {
                                                        focusedField = .password
                                                    }
                                                },
                                        )
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(.quinary, in: .rect(cornerRadius: 6))
                        .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))

                        Button {
                            dismiss()

                            appState.isRestorePresented = true
                        } label: {
                            Text("key.password.lost")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
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
                                .contentShape(.rect(cornerRadius: 6))
                                .background(!username.isEmpty && !password.isEmpty ? Color.accentColor : Color.secondary, in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(username.isEmpty || password.isEmpty)
                        .animation(.easeInOut, value: !username.isEmpty && !password.isEmpty)

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

                    HStack(alignment: .center, spacing: 8) {
                        Text("key.sign_in.sign_up.q").font(.caption)

                        Button {
                            dismiss()

                            appState.isSignUpPresented = true
                        } label: {
                            Text(verbatim: "\(String(localized: "key.register"))!")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onAppear {
                    focusedField = .username
                }
            case .loading:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.circle")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)

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
                            subscriptions.flush()

                            withAnimation(.easeInOut) {
                                state = .data
                            }
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .contentShape(.rect(cornerRadius: 6))
                                .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .error:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.circle")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)

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
                                .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6))
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
        .analyticsScreen(name: "SignInSheet")
    }

    private func load() {
        withAnimation(.easeInOut) {
            state = .loading
        }

        signInUseCase(login: username, password: password)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case .failure = completion else { return }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut) {
                        state = .error
                    }
                }
            } receiveValue: { success in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if success {
                        dismiss()
                    } else {
                        withAnimation(.easeInOut) {
                            state = .error
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }
}

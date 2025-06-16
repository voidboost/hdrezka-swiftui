import Combine
import FactoryKit
import SwiftUI

struct RestoreSheetView: View {
    @Injected(\.restoreUseCase) private var restoreUseCase

    @State private var subscriptions: Set<AnyCancellable> = []

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var appState: AppState

    @State private var login: String = ""
    @State private var state: EmptyState = .data
    @State private var email: String = ""

    @State private var isSuccessPresented: Bool = false

    private enum FocusedField {
        case login
    }

    @FocusState private var focusedField: FocusedField?

    var body: some View {
        Group {
            switch state {
            case .data:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.accentColor)

                        Text("key.restore.label")
                            .font(.largeTitle.weight(.semibold))

                        Text("key.password.lost")
                            .font(.title3)
                            .lineLimit(2, reservesSpace: true)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .center, spacing: 8) {
                        VStack(spacing: 2.5) {
                            HStack(alignment: .center, spacing: 8) {
                                Text("key.username.full")

                                TextField("key.username.full", text: $login, prompt: Text(String(localized: "key.username.full").lowercased()))
                                    .textFieldStyle(.plain)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .login)
                                    .onChange(of: login) {
                                        let newValue = String(login.unicodeScalars.filter { CharacterSet.whitespacesAndNewlines.inverted.contains($0) })
                                        if newValue != login {
                                            login = newValue
                                        }
                                    }
                                    .onSubmit {
                                        if !login.isEmpty {
                                            load()
                                        }
                                    }
                            }
                            .padding(.vertical, 10)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(.quinary)
                        .clipShape(.rect(cornerRadius: 6))
                        .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                    }

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            load()
                        } label: {
                            Text("key.restore")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .background(!login.isEmpty ? Color.accentColor : Color.secondary)
                                .clipShape(.rect(cornerRadius: 6))
                                .contentShape(.rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(login.isEmpty)
                        .animation(.easeInOut, value: !login.isEmpty)

                        Button {
                            dismiss()

                            appState.isSignInPresented = true
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .background(.quinary.opacity(0.5))
                                .clipShape(.rect(cornerRadius: 6))
                                .contentShape(.rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .task {
                    focusedField = .login
                }
            case .loading:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.accentColor)

                        Text("key.restore.enter")
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
                                .background(.quinary.opacity(0.5))
                                .clipShape(.rect(cornerRadius: 6))
                                .contentShape(.rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .error:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.accentColor)

                        Text("key.ops")
                            .font(.largeTitle.weight(.semibold))

                        Text("key.username.email.error")
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
                                .background(Color.accentColor)
                                .clipShape(.rect(cornerRadius: 6))
                                .contentShape(.rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()

                            appState.isSignInPresented = true
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .background(.quinary.opacity(0.5))
                                .clipShape(.rect(cornerRadius: 6))
                                .contentShape(.rect(cornerRadius: 6))
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
        .alert("key.restore.success", isPresented: $isSuccessPresented) {
            Button(role: .cancel) {
                dismiss()

                appState.isSignInPresented = true
            } label: {
                Text("key.ok")
            }
        } message: {
            Text("key.restore.success.message-\(email)")
        }
    }

    private func load() {
        withAnimation(.easeInOut) {
            state = .loading
        }

        restoreUseCase(login: login)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case .failure = completion else { return }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut) {
                        state = .error
                    }
                }
            } receiveValue: { email in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let email, !email.isEmpty {
                        self.email = email
                        isSuccessPresented = true
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

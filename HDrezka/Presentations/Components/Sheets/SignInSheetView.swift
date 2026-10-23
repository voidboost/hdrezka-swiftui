import ComposableArchitecture
import Defaults
import FirebaseAnalytics
import SwiftUI

struct SignInSheetView: View {
    @Bindable var store: StoreOf<SignInFeature>

    @Environment(\.dismiss) private var dismiss


    @State private var showPassword: Bool = false
    @State private var passwordIsEmpty: Bool = true

    private enum FocusedField {
        case username, password
    }

    @FocusState private var focusedField: FocusedField?

    var body: some View {
        Group {
            if store.status.isLoading {
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
                            store.send(.cancelRequest, animation: .easeInOut)
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .contentShape(.rect(cornerRadius: 6))
                                .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
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

                                TextField("key.username", text: $store.username, prompt: Text(String(localized: "key.username.full").lowercased()))
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
                                    TextField("key.password", text: $store.password, prompt: Text(String(localized: "key.password").lowercased()))
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .password)
                                        .onChange(of: store.password) {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                passwordIsEmpty = store.password.isEmpty
                                            }
                                        }
                                        .onSubmit {
                                            if !store.username.isEmpty, !store.password.isEmpty {
                                                store.send(.submit)
                                            }
                                        }
                                } else {
                                    SecureField("key.password", text: $store.password, prompt: Text(String(localized: "key.password").lowercased()))
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .password)
                                        .onChange(of: store.password) {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                passwordIsEmpty = store.password.isEmpty
                                            }
                                        }
                                        .onSubmit {
                                            if !store.username.isEmpty, !store.password.isEmpty {
                                                store.send(.submit)
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
                            store.send(.restoreTapped)
                        } label: {
                            Text("key.password.lost")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            store.send(.submit)
                        } label: {
                            Text("key.sign_in")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .contentShape(.rect(cornerRadius: 6))
                                .background(!store.username.isEmpty && !store.password.isEmpty ? Color.accentColor : Color.secondary, in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(store.username.isEmpty || store.password.isEmpty)
                        .animation(.easeInOut, value: !store.username.isEmpty && !store.password.isEmpty)

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
                            store.send(.signUpTapped)
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
            }
        }
        .padding(.horizontal, 35)
        .padding(.top, 35)
        .padding(.bottom, 25)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 520)
        .analyticsScreen(name: "sign_in_sheet", class: "SignInSheetView")
        .alert("key.ops", isPresented: Binding { store.status.error != nil } set: { _ in }) {
            Button {
                store.send(.retry, animation: .easeInOut)
            } label: {
                Text("key.retry")
            }

            Button(role: .cancel) {
                dismiss()
            } label: {
                Text("key.cancel")
            }
        } message: {
            if let error = store.status.error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
    }
}

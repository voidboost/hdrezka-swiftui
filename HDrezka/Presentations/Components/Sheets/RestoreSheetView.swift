import ComposableArchitecture
import FirebaseAnalytics
import SwiftUI

struct RestoreSheetView: View {
    @Bindable var store: StoreOf<RestoreFeature>

    @Environment(\.dismiss) private var dismiss



    private enum FocusedField {
        case login
    }

    @FocusState private var focusedField: FocusedField?

    var body: some View {
        Group {
            switch store.status {
            case .data:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.largeTitle)
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

                                TextField("key.username.full", text: $store.login, prompt: Text(String(localized: "key.username.full").lowercased()))
                                    .textFieldStyle(.plain)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .login)
                                    .onSubmit {
                                        if !store.login.isEmpty {
                                            store.send(.submit)
                                        }
                                    }
                            }
                            .padding(.vertical, 10)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(.quinary, in: .rect(cornerRadius: 6))
                        .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                    }

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            store.send(.submit)
                        } label: {
                            Text("key.restore")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .contentShape(.rect(cornerRadius: 6))
                                .background(!store.login.isEmpty ? Color.accentColor : Color.secondary, in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(store.login.isEmpty)
                        .animation(.easeInOut, value: !store.login.isEmpty)

                        Button {
                            store.send(.signInTapped)
                        } label: {
                            Text("key.cancel")
                                .frame(width: 250, height: 30)
                                .contentShape(.rect(cornerRadius: 6))
                                .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6)).background(Color.accentColor, in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onAppear {
                    focusedField = .login
                }
            case .loading:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.largeTitle)
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
            case .error:
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.largeTitle)
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
                            store.send(.signInTapped)
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
        .alert("key.restore.success", isPresented: $store.isSuccessPresented) {
            Button(role: .cancel) {
                store.send(.signInTapped)
            } label: {
                Text("key.ok")
            }
        } message: {
            Text("key.restore.success.message-\(store.email)")
        }
        .analyticsScreen(name: "restore_sheet", class: "RestoreSheetView")
    }
}

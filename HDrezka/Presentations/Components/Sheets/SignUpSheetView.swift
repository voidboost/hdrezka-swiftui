import Combine
import Defaults
import FactoryKit
import FirebaseAnalytics
import SwiftUI
import ValidatorCore

struct SignUpSheetView: View {
    @Injected(\.signUpUseCase) private var signUpUseCase

    @Environment(\.dismiss) private var dismiss

    @Environment(AppState.self) private var appState

    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password1: String = ""
    @State private var password2: String = ""
    @State private var verifyCode: String = ""
    @State private var state: EmptyState = .data

    private enum FocusedField {
        case email, username, password1, password2, verifyCode
    }

    @FocusState private var focusedField: FocusedField?

    private let validator = Validator()

    @State private var confirmPasswordValidResult: ValidationResult?
    @State private var confirmPasswordCheck: DispatchWorkItem?
    private var confirmPasswordValid: Bool {
        if case .valid = confirmPasswordValidResult {
            true
        } else {
            false
        }
    }

    @State private var showPassword: Bool = false
    @State private var passwordIsEmpty: Bool = true
    @State private var showConfirmPassword: Bool = false
    @State private var confirmPasswordIsEmpty: Bool = true

    private enum Step: Int, CaseIterable, Identifiable {
        case first = 1
        case second
        case third

        var id: Self {
            self
        }
    }

    @State private var step: Step = .first

    @State private var showPremiumWarning: Bool = true

    @State private var subscriptions: Set<AnyCancellable> = []

    var body: some View {
        Group {
            if state.isLoading {
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)

                        Text("key.sign_up.enter")
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
            } else {
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 5) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)

                        Text("key.sign_up.label")
                            .font(.largeTitle.weight(.semibold))

                        Text("key.sign_up.description")
                            .font(.title3)
                            .lineLimit(2, reservesSpace: true)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .center, spacing: 8) {
                        VStack(spacing: 2.5) {
                            if step == .first {
                                HStack(alignment: .center, spacing: 8) {
                                    Text("key.email")

                                    TextField("key.email", text: $email, prompt: Text(String(localized: "key.email").lowercased()))
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: FocusedField.email)
                                        .onSubmit {
                                            focusedField = .username
                                        }
                                }
                                .padding(.vertical, 10)

                                Divider()

                                HStack(alignment: .center, spacing: 8) {
                                    Text("key.username")

                                    TextField("key.username", text: $username, prompt: Text(String(localized: "key.username").lowercased()))
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .username)
                                        .onSubmit {
                                            focusedField = .password1
                                        }
                                }
                                .padding(.vertical, 10)

                                Divider()

                                HStack(alignment: .center, spacing: 8) {
                                    Text("key.password")

                                    if showPassword {
                                        TextField("key.password", text: $password1, prompt: Text(String(localized: "key.password").lowercased()))
                                            .textFieldStyle(.plain)
                                            .multilineTextAlignment(.trailing)
                                            .focused($focusedField, equals: .password1)
                                            .onChange(of: password1) {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    passwordIsEmpty = password1.isEmpty
                                                }

                                                withAnimation(.easeInOut) {
                                                    confirmPasswordValidResult = nil
                                                }

                                                confirmPasswordCheck?.cancel()

                                                if !password1.isEmpty, !password2.isEmpty {
                                                    confirmPasswordCheck = DispatchWorkItem {
                                                        withAnimation(.easeInOut) {
                                                            confirmPasswordValidResult = validator.validate(input: password2, rule: EqualityValidationRule(compareTo: password1, error: String(localized: "key.password.confirm.error")))
                                                        }
                                                    }

                                                    if let confirmPasswordCheck {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: confirmPasswordCheck)
                                                    }
                                                }
                                            }
                                            .onSubmit {
                                                focusedField = .password2
                                            }
                                    } else {
                                        SecureField("key.password", text: $password1, prompt: Text(String(localized: "key.password").lowercased()))
                                            .textFieldStyle(.plain)
                                            .multilineTextAlignment(.trailing)
                                            .focused($focusedField, equals: .password1)
                                            .onChange(of: password1) {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    passwordIsEmpty = password1.isEmpty
                                                }

                                                withAnimation(.easeInOut) {
                                                    confirmPasswordValidResult = nil
                                                }

                                                confirmPasswordCheck?.cancel()

                                                if !password1.isEmpty, !password2.isEmpty {
                                                    confirmPasswordCheck = DispatchWorkItem {
                                                        withAnimation(.easeInOut) {
                                                            confirmPasswordValidResult = validator.validate(input: password2, rule: EqualityValidationRule(compareTo: password1, error: String(localized: "key.password.confirm.error")))
                                                        }
                                                    }

                                                    if let confirmPasswordCheck {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: confirmPasswordCheck)
                                                    }
                                                }
                                            }
                                            .onSubmit {
                                                focusedField = .password2
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
                                                            focusedField = .password1
                                                        }
                                                    },
                                            )
                                    }
                                }
                                .padding(.vertical, 10)

                                Divider()

                                HStack(alignment: .center, spacing: 8) {
                                    Text("key.password.confirm")

                                    if showConfirmPassword {
                                        TextField("key.password.confirm", text: $password2, prompt: Text(String(localized: "key.password.confirm").lowercased()))
                                            .textFieldStyle(.plain)
                                            .multilineTextAlignment(.trailing)
                                            .focused($focusedField, equals: .password2)
                                            .onChange(of: password2) {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    confirmPasswordIsEmpty = password2.isEmpty
                                                }

                                                withAnimation(.easeInOut) {
                                                    confirmPasswordValidResult = nil
                                                }

                                                confirmPasswordCheck?.cancel()

                                                if !password1.isEmpty, !password2.isEmpty {
                                                    confirmPasswordCheck = DispatchWorkItem {
                                                        withAnimation(.easeInOut) {
                                                            confirmPasswordValidResult = validator.validate(input: password2, rule: EqualityValidationRule(compareTo: password1, error: String(localized: "key.password.confirm.error")))
                                                        }
                                                    }

                                                    if let confirmPasswordCheck {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: confirmPasswordCheck)
                                                    }
                                                }
                                            }
                                            .onSubmit {
                                                if confirmPasswordValid {
                                                    load()
                                                }
                                            }
                                    } else {
                                        SecureField("key.password.confirm", text: $password2, prompt: Text(String(localized: "key.password.confirm").lowercased()))
                                            .textFieldStyle(.plain)
                                            .multilineTextAlignment(.trailing)
                                            .focused($focusedField, equals: .password2)
                                            .onChange(of: password2) {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    confirmPasswordIsEmpty = password2.isEmpty
                                                }

                                                withAnimation(.easeInOut) {
                                                    confirmPasswordValidResult = nil
                                                }

                                                confirmPasswordCheck?.cancel()

                                                if !password1.isEmpty, !password2.isEmpty {
                                                    confirmPasswordCheck = DispatchWorkItem {
                                                        withAnimation(.easeInOut) {
                                                            confirmPasswordValidResult = validator.validate(input: password2, rule: EqualityValidationRule(compareTo: password1, error: String(localized: "key.password.confirm.error")))
                                                        }
                                                    }

                                                    if let confirmPasswordCheck {
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: confirmPasswordCheck)
                                                    }
                                                }
                                            }
                                            .onSubmit {
                                                if confirmPasswordValid {
                                                    load()
                                                }
                                            }
                                    }

                                    if !confirmPasswordIsEmpty {
                                        Image(systemName: "eye")
                                            .foregroundStyle(Color.accentColor.opacity(showConfirmPassword ? 0.5 : 1))
                                            .simultaneousGesture(
                                                DragGesture(minimumDistance: 0)
                                                    .onChanged { _ in
                                                        withAnimation(.easeInOut(duration: 0.15)) {
                                                            showConfirmPassword = true
                                                        }
                                                    }
                                                    .onEnded { _ in
                                                        withAnimation(.easeInOut(duration: 0.15)) {
                                                            showConfirmPassword = false
                                                        } completion: {
                                                            focusedField = .password2
                                                        }
                                                    },
                                            )
                                    }
                                }
                                .padding(.vertical, 10)
                                .overlay(alignment: .bottomLeading) {
                                    if case let .invalid(errors) = confirmPasswordValidResult,
                                       let error = errors.first
                                    {
                                        Text(error.message.lowercased())
                                            .font(.caption)
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .onAppear {
                                    focusedField = .email
                                }
                            } else if step == .third {
                                HStack(alignment: .center, spacing: 8) {
                                    Text("key.verify.code")

                                    TextField("key.verify.code", text: $verifyCode, prompt: Text(String(localized: "key.verify.code").lowercased()))
                                        .textFieldStyle(.plain)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .verifyCode)
                                        .onSubmit {
                                            load()
                                        }
                                }
                                .padding(.vertical, 10)
                                .onAppear {
                                    focusedField = .verifyCode
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(.quinary, in: .rect(cornerRadius: 6))
                        .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                    }

                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            load()
                        } label: {
                            Text("key.sign_up")
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .contentShape(.rect(cornerRadius: 6))
                                .background(confirmPasswordValid ? Color.accentColor : Color.secondary, in: .rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(!confirmPasswordValid)

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
                        Text("key.sign_up.sign_in.q").font(.caption)

                        Button {
                            dismiss()

                            appState.isSignInPresented = true
                        } label: {
                            Text(verbatim: "\(String(localized: "key.sign_in"))!")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
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
        .analyticsScreen(name: "sign_up_sheet", class: "SignUpSheetView")
        .alert("key.ops", isPresented: Binding { state.error != nil } set: { _ in }) {
            Button {
                withAnimation(.easeInOut) {
                    state = .data
                }
            } label: {
                Text("key.retry")
            }

            Button(role: .cancel) {
                dismiss()
            } label: {
                Text("key.cancel")
            }
        } message: {
            if let error = state.error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
        .confirmationDialog("key.verify.code", isPresented: Binding { step == .second && state.error == nil } set: { _ in }) {
            Button {
                load()
            } label: {
                Text("key.continue")
            }

            Button(role: .cancel) {
                withAnimation(.easeInOut) {
                    step = .first
                }
            } label: {
                Text("key.cancel")
            }
        } message: {
            Text("ket.verify.code-\(email)")
        }
        .alert("key.sign_up.premium", isPresented: $showPremiumWarning) {
            Button(role: .cancel) {} label: {
                Text("key.ok")
            }
        } message: {
            Text("key.sign_up.premium.description")
        }
        .dialogSeverity(.critical)
    }

    private func load() {
        withAnimation(.easeInOut) {
            state = .loading
        }

        signUpUseCase(email: email, login: username, password: password1, verifyCode: verifyCode, step: step.rawValue)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                withAnimation(.easeInOut) {
                    state = .error(error)
                }
            } receiveValue: { _ in
                if step == Step.allCases.last {
                    dismiss()
                } else {
                    withAnimation(.easeInOut) {
                        step = Step.allCases.element(after: step) ?? .first
                        state = .data
                    }
                }
            }
            .store(in: &subscriptions)
    }
}

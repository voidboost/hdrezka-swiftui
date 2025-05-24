import Combine
import Defaults
import FactoryKit
import SwiftUI

struct SignUpSheetView: View {
    @Injected(\.signUpUseCase) private var signUpUseCase
    @Injected(\.checkEmailUseCase) private var checkEmailUseCase
    @Injected(\.checkUsernameUseCase) private var checkUsernameUseCase

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var appState: AppState

    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password1: String = ""
    @State private var password2: String = ""
    @State private var state: EmptyState = .data

    private enum FocusedField {
        case email, username, password1, password2
    }

    @FocusState private var focusedField: FocusedField?

    @State private var emailValid: Bool?
    @State private var usernameValid: Bool?
    @State private var passwordValid: Bool?
    @State private var confirmPasswordValid: Bool?

    @State private var emailCheck: DispatchWorkItem?
    @State private var usernameCheck: DispatchWorkItem?
    @State private var passwordCheck: DispatchWorkItem?
    @State private var confirmPasswordCheck: DispatchWorkItem?

    @State private var showPassword: Bool = false
    @State private var passwordIsEmpty: Bool = true
    @State private var showConfirmPassword: Bool = false
    @State private var confirmPasswordIsEmpty: Bool = true

    @State private var showSignUpWarning: Bool = true

    @State private var subscriptions: Set<AnyCancellable> = []

    var body: some View {
        if showSignUpWarning {
            VStack(alignment: .center, spacing: 25) {
                VStack(alignment: .center, spacing: 5) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.accent)
                    
                    Text("key.sign_up.label")
                        .font(.largeTitle.weight(.semibold))
                    
                    Text("key.sign_up.description")
                        .font(.title3)
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .center, spacing: 8) {
                    VStack(spacing: 6) {
                        HStack(alignment: .center) {
                            Image(systemName: "info.circle")
                            Text("key.sign_up_temporarily_unavailable")
                        }
                        
                        Button {
                            withAnimation(.easeInOut) {
                                showSignUpWarning = false
                            }
                        } label: {
                            Text("key.try_anyway")
                                .frame(height: 30)
                                .frame(maxWidth: .infinity)
                                .background(.quinary.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(15)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.accent, lineWidth: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("key.sign_up_info_tutorial_title")
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                        
                        HStack(alignment: .top, spacing: 6) {
                            Text("1").monospacedDigit()
                                
                            Text("key.sign_up_info_tutorial_step_1")
                                .multilineTextAlignment(.leading)
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            Text("2").monospacedDigit()
                                
                            VStack(alignment: .leading, spacing: 6) {
                                Text("key.sign_up_info_tutorial_step_2")
                                    .multilineTextAlignment(.leading)
                                    
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "info.circle")
                                        
                                    Text("key.sign_up_info_tutorial_step_2_1")
                                        .multilineTextAlignment(.leading)
                                }
                                    
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "info.circle")
                                        
                                    Text("key.sign_up_info_tutorial_step_2_2")
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 6) {
                                Text("3").monospacedDigit()
                                
                                Text("key.sign_up_info_tutorial_step_3")
                                    .multilineTextAlignment(.leading)
                            }

                            Button {
                                dismiss()
                                
                                appState.isSignInPresented = true
                            } label: {
                                Text("key.sign_in")
                                    .frame(height: 30)
                                    .frame(maxWidth: .infinity)
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
                                    .frame(height: 30)
                                    .frame(maxWidth: .infinity)
                                    .background(.quinary.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .contentShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(15)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.tertiary, lineWidth: 1)
                    }
                }
            }
            .padding(.horizontal, 35)
            .padding(.top, 35)
            .padding(.bottom, 25)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: 520)
        } else {
            Group {
                switch state {
                case .data:
                    VStack(alignment: .center, spacing: 25) {
                        VStack(alignment: .center, spacing: 5) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 48))
                                .foregroundStyle(.accent)
                            
                            Text("key.sign_up.label")
                                .font(.largeTitle.weight(.semibold))
                            
                            Text("key.sign_up.description")
                                .font(.title3)
                                .lineLimit(2, reservesSpace: true)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(alignment: .center, spacing: 8) {
                            VStack(spacing: 2.5) {
                                ZStack(alignment: .bottomLeading) {
                                    HStack(alignment: .center, spacing: 8) {
                                        Text("key.email")
                                        
                                        TextField("key.email", text: $email, prompt: Text(String(localized: "key.email").lowercased()))
                                            .textFieldStyle(.plain)
                                            .multilineTextAlignment(.trailing)
                                            .focused($focusedField, equals: FocusedField.email)
                                            .customOnChange(of: email) {
                                                let newValue = String(email.unicodeScalars.filter { CharacterSet.whitespacesAndNewlines.inverted.contains($0) })
                                                if newValue != email {
                                                    email = newValue
                                                } else {
                                                    emailValid = nil
                                                    
                                                    emailCheck?.cancel()
                                                    
                                                    if !email.isEmpty {
                                                        emailCheck = DispatchWorkItem {
                                                            checkEmailUseCase(email: email)
                                                                .receive(on: DispatchQueue.main)
                                                                .sink { completion in
                                                                    guard case .failure = completion else { return }
                                                                    
                                                                    emailValid = false
                                                                } receiveValue: { valid in
                                                                    emailValid = valid
                                                                }
                                                                .store(in: &subscriptions)
                                                        }
                                                        
                                                        if let emailCheck {
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: emailCheck)
                                                        }
                                                    }
                                                }
                                            }
                                            .onSubmit {
                                                focusedField = .username
                                            }
                                    }
                                    .padding(.vertical, 10)
                                    
                                    Text(String(localized: "key.email.error").lowercased())
                                        .font(.caption)
                                        .foregroundStyle(emailValid == false ? .accent : .clear)
                                        .animation(.easeInOut, value: emailValid == false)
                                }
                                
                                Divider()
                                
                                ZStack(alignment: .bottomLeading) {
                                    HStack(alignment: .center, spacing: 8) {
                                        Text("key.username")
                                        
                                        TextField("key.username", text: $username, prompt: Text(String(localized: "key.username").lowercased()))
                                            .textFieldStyle(.plain)
                                            .multilineTextAlignment(.trailing)
                                            .focused($focusedField, equals: .username)
                                            .customOnChange(of: username) {
                                                let newValue = String(username.unicodeScalars.filter { CharacterSet.whitespacesAndNewlines.inverted.contains($0) }.prefix(30))
                                                if newValue != username {
                                                    username = newValue
                                                } else {
                                                    usernameValid = nil
                                                    
                                                    usernameCheck?.cancel()
                                                    if !username.isEmpty {
                                                        usernameCheck = DispatchWorkItem {
                                                            checkUsernameUseCase(username: username)
                                                                .receive(on: DispatchQueue.main)
                                                                .sink { completion in
                                                                    guard case .failure = completion else { return }
                                                                    
                                                                    usernameValid = false
                                                                } receiveValue: { valid in
                                                                    usernameValid = valid
                                                                }
                                                                .store(in: &subscriptions)
                                                        }
                                                        
                                                        if let usernameCheck {
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: usernameCheck)
                                                        }
                                                    }
                                                }
                                            }
                                            .onSubmit {
                                                focusedField = .password1
                                            }
                                    }
                                    .padding(.vertical, 10)
                                    
                                    Text(String(localized: "key.username.error").lowercased())
                                        .font(.caption)
                                        .foregroundStyle(usernameValid == false ? .accent : .clear)
                                        .animation(.easeInOut, value: usernameValid == false)
                                }
                                
                                Divider()
                                
                                ZStack(alignment: .bottomLeading) {
                                    HStack(alignment: .center, spacing: 8) {
                                        Text("key.password")
                                        
                                        if showPassword {
                                            TextField("key.password", text: $password1, prompt: Text(String(localized: "key.password").lowercased()))
                                                .textFieldStyle(.plain)
                                                .multilineTextAlignment(.trailing)
                                                .focused($focusedField, equals: .password1)
                                                .customOnChange(of: password1) {
                                                    let newValue = String(password1.unicodeScalars.filter { CharacterSet.whitespacesAndNewlines.inverted.contains($0) })
                                                    if newValue != password1 {
                                                        password1 = newValue
                                                    } else {
                                                        withAnimation(.easeInOut(duration: 0.15)) {
                                                            passwordIsEmpty = newValue.isEmpty
                                                        }
                                                        
                                                        passwordValid = nil
                                                        
                                                        passwordCheck?.cancel()
                                                        if !password1.isEmpty {
                                                            passwordCheck = DispatchWorkItem {
                                                                passwordValid = password1.count >= 6
                                                                
                                                                if !password2.isEmpty {
                                                                    confirmPasswordValid = password1 == password2
                                                                }
                                                            }
                                                            
                                                            if let passwordCheck {
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: passwordCheck)
                                                            }
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
                                                .customOnChange(of: password1) {
                                                    let newValue = String(password1.unicodeScalars.filter { CharacterSet.whitespacesAndNewlines.inverted.contains($0) })
                                                    if newValue != password1 {
                                                        password1 = newValue
                                                    } else {
                                                        withAnimation(.easeInOut(duration: 0.15)) {
                                                            passwordIsEmpty = newValue.isEmpty
                                                        }
                                                        
                                                        passwordValid = nil
                                                        
                                                        passwordCheck?.cancel()
                                                        if !password1.isEmpty {
                                                            passwordCheck = DispatchWorkItem {
                                                                passwordValid = password1.count >= 6
                                                                
                                                                if !password2.isEmpty {
                                                                    confirmPasswordValid = password1 == password2
                                                                }
                                                            }
                                                            
                                                            if let passwordCheck {
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: passwordCheck)
                                                            }
                                                        }
                                                    }
                                                }
                                                .onSubmit {
                                                    focusedField = .password2
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
                                                                focusedField = .password1
                                                            }
                                                        }
                                                )
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    
                                    Text(String(localized: "key.password.error").lowercased())
                                        .font(.caption)
                                        .foregroundStyle(passwordValid == false ? .accent : .clear)
                                        .animation(.easeInOut, value: passwordValid == false)
                                }
                                
                                Divider()
                                
                                ZStack(alignment: .bottomLeading) {
                                    HStack(alignment: .center, spacing: 8) {
                                        Text("key.password.confirm")
                                        
                                        if showConfirmPassword {
                                            TextField("key.password.confirm", text: $password2, prompt: Text(String(localized: "key.password.confirm").lowercased()))
                                                .textFieldStyle(.plain)
                                                .multilineTextAlignment(.trailing)
                                                .focused($focusedField, equals: .password2)
                                                .customOnChange(of: password2) {
                                                    let newValue = String(password2.unicodeScalars.filter { CharacterSet.whitespacesAndNewlines.inverted.contains($0) })
                                                    if newValue != password2 {
                                                        password2 = newValue
                                                    } else {
                                                        withAnimation(.easeInOut(duration: 0.15)) {
                                                            confirmPasswordIsEmpty = newValue.isEmpty
                                                        }
                                                        
                                                        confirmPasswordValid = nil
                                                        
                                                        confirmPasswordCheck?.cancel()
                                                        if !password2.isEmpty {
                                                            confirmPasswordCheck = DispatchWorkItem {
                                                                confirmPasswordValid = password1 == password2
                                                            }
                                                            
                                                            if let confirmPasswordCheck {
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: confirmPasswordCheck)
                                                            }
                                                        }
                                                    }
                                                }
                                                .onSubmit {
                                                    if emailValid == true, usernameValid == true, passwordValid == true, confirmPasswordValid == true {
                                                        withAnimation(.easeInOut) {
                                                            state = .loading
                                                        }
                                                        
                                                        signUpUseCase(email: email, login: username, password: password1)
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
                                        } else {
                                            SecureField("key.password.confirm", text: $password2, prompt: Text(String(localized: "key.password.confirm").lowercased()))
                                                .textFieldStyle(.plain)
                                                .multilineTextAlignment(.trailing)
                                                .focused($focusedField, equals: .password2)
                                                .customOnChange(of: password2) {
                                                    let newValue = String(password2.unicodeScalars.filter { CharacterSet.whitespacesAndNewlines.inverted.contains($0) })
                                                    if newValue != password2 {
                                                        password2 = newValue
                                                    } else {
                                                        withAnimation(.easeInOut(duration: 0.15)) {
                                                            confirmPasswordIsEmpty = newValue.isEmpty
                                                        }
                                                        
                                                        confirmPasswordValid = nil
                                                        
                                                        confirmPasswordCheck?.cancel()
                                                        if !password2.isEmpty {
                                                            confirmPasswordCheck = DispatchWorkItem {
                                                                confirmPasswordValid = password1 == password2
                                                            }
                                                            
                                                            if let confirmPasswordCheck {
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: confirmPasswordCheck)
                                                            }
                                                        }
                                                    }
                                                }
                                                .onSubmit {
                                                    if emailValid == true, usernameValid == true, passwordValid == true, confirmPasswordValid == true {
                                                        withAnimation(.easeInOut) {
                                                            state = .loading
                                                        }
                                                        
                                                        signUpUseCase(email: email, login: username, password: password1)
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
                                        }
                                        
                                        if !confirmPasswordIsEmpty {
                                            Image(systemName: "eye")
                                                .foregroundStyle(.accent.opacity(showConfirmPassword ? 0.5 : 1))
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
                                                            }
                                                            
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                                                focusedField = .password2
                                                            }
                                                        }
                                                )
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    
                                    Text(String(localized: "key.password.confirm.error").lowercased())
                                        .font(.caption)
                                        .foregroundStyle(confirmPasswordValid == false ? .accent : .clear)
                                        .animation(.easeInOut, value: confirmPasswordValid == false)
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 5)
                            .background(.quinary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.tertiary, lineWidth: 1)
                            }
                        }
                        
                        VStack(alignment: .center, spacing: 10) {
                            Button {
                                withAnimation(.easeInOut) {
                                    state = .loading
                                }
                                
                                signUpUseCase(email: email, login: username, password: password1)
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
                            } label: {
                                Text("key.sign_up")
                                    .frame(width: 250, height: 30)
                                    .foregroundStyle(.white)
                                    .background(emailValid == true && usernameValid == true && passwordValid == true && confirmPasswordValid == true ? .accent : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .contentShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .disabled(emailValid != true || usernameValid != true || passwordValid != true || confirmPasswordValid != true)
                            .animation(.easeInOut, value: emailValid == true && usernameValid == true && passwordValid == true && confirmPasswordValid == true)
                            
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
                            Text("key.sign_up.sign_in.q").font(.caption)
                            
                            Button {
                                dismiss()
                                
                                appState.isSignInPresented = true
                            } label: {
                                Text("\(String(localized: "key.sign_in"))!")
                                    .font(.caption)
                                    .foregroundStyle(.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .task {
                        focusedField = .email
                    }
                case .loading:
                    VStack(alignment: .center, spacing: 25) {
                        VStack(alignment: .center, spacing: 5) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 48))
                                .foregroundStyle(.accent)
                            
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
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 48))
                                .foregroundStyle(.accent)
                            
                            Text("key.ops")
                                .font(.largeTitle.weight(.semibold))
                            
                            Text("key.sign_up.error")
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
    }
}

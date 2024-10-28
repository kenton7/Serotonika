//
//  RegisterView.swift
//  Relax
//
//  Created by Илья Кузнецов on 21.06.2024.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import YandexLoginSDK
import AuthenticationServices
import CryptoKit

struct RegisterView: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var isEmailEditing = false
    @State private var isShowingPassword = false
    @State private var isAgreeWithPrivacy = false
    @State private var isRegistered: Bool = false
    @State private var isErrorWhileRegister: Bool = false
    @State private var errorMessage: String?
    @State private var userID: String?
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var isRegistration = false
    @State private var isPrivacyPolicyPressed = false
    @State private var isTermsAndConditionsPressed = false
    @StateObject private var yandexAuth = YandexAuthorization.shared
    @StateObject private var databaseVM = ChangeDataInDatabase.shared
    private let locale = Locale.current
    @Environment(\.colorScheme) private var scheme
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Image("LoginBackground")
                        .ignoresSafeArea()
                    Spacer()
                }
                VStack {
                    Spacer()
                    Text("Создайте новый аккаунт")
                        .padding(.horizontal, 10)
                        .minimumScaleFactor(0.5)
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    Spacer()
                    //MARK: - Кнопки авторизации через Yandex и VK
                    Button {
                        if let rootViewController = getRootViewController() {
                            do {
                                guard isAgreeWithPrivacy else {
                                    errorMessage = "Сначала нужно принять условия использования."
                                    return
                                }
                                try YandexLoginSDK.shared.authorize(with: rootViewController,
                                                                    customValues: nil,
                                                                    authorizationStrategy: .webOnly)
                            } catch {
                                print("Ошибка запуска авторизации: \(error.localizedDescription)")
                                isRegistration = false
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(activeDarkModel ? .white : .black)
                            HStack {
                                Image("Yandex")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                Text("Войти с Яндекс ID")
                                    .foregroundStyle(activeDarkModel ? .black : .white)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .padding(.horizontal)
                    .clipShape(.rect(cornerRadius: 16))
                    
                    //Кнопка Войти через Apple. НЕ должна быть доступна для пользователей из РФ!
                    if locale.identifier != "ru_RU" {
                        SignInWithAppleButton(.signUp) { request in
                            guard isAgreeWithPrivacy else {
                                    errorMessage = "Сначала нужно принять условия использования."
                                    isErrorWhileRegister = true
                                    return
                                }
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = viewModel.currentNonce
                        } onCompletion: { result in
                            guard isAgreeWithPrivacy else {
                                errorMessage = "Сначала нужно принять условия использования."
                                isRegistration = false
                                self.isRegistered = false
                                return
                            }
                            switch result {
                            case .success(let authorization):
                                Task {
                                    await viewModel.signInWithApple(authorization)
                                    if let userID = Auth.auth().currentUser?.uid {
                                        await databaseVM.checkIfFirebaseUserViewedTutorial(userID: userID)
                                    }
                                    await MainActor.run {
                                        self.isRegistered = true
                                    }
                                }
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                                isErrorWhileRegister = true
                                isRegistration = false
                                self.isRegistered = false
                            }
                        }
                        .foregroundStyle(scheme == .dark ? .black : .white)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay {
                            ZStack {
                                Capsule()
                                HStack {
                                    Image(systemName: "applelogo")
                                    Text("Вход с Apple")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(scheme == .dark ? .black : .white)
                            }
                            .allowsHitTesting(false)
                        }
                        .padding(.horizontal)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .clipShape(.rect(cornerRadius: 16))
                    }
                    
                    Divider()
                    Text("ИЛИ ЗАРЕГИСТРИРУЙТЕСЬ С ПОМОЩЬЮ EMAIL")
                        .font(.system(size: 15))
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                    Spacer()
                    
                    TextField("Как Вас зовут?", text: $name)
                        .padding()
                        .background(activeDarkModel ? .black : Color(uiColor: .init(red: 242/255, green: 243/255, blue: 247/255, alpha: 1)))
                        .clipShape(.rect(cornerRadius: 8))
                        .padding()
                        .autocorrectionDisabled(true)
                        .padding(.horizontal)
                        .font(.system(size: 17, weight: .light, design: .rounded))
                    
                    VStack {
                        EmailFieldView("Email", email: $email)
                            .padding(.horizontal)
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .padding(.horizontal)
                                .bold()
                                .foregroundStyle(.red)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    PasswordFieldView("Пароль", text: $password)
                        .padding(.horizontal)
                    Spacer()
                    
                    Group {
                        HStack(spacing: 3) {
                            Text("Я прочитал(-а)")
                                .padding(.leading, 1)
                                //.padding(.horizontal)
                                .font(.system(size: 9, weight: .light, design: .rounded))
                            Button(action: {
                                isPrivacyPolicyPressed = true
                            }, label: {
                                Text("политику конфиденциальности")
                                    .foregroundStyle(.blue)
                                    .font(.system(size: 9, weight: .light, design: .rounded))
                            })
                            .sheet(isPresented: $isPrivacyPolicyPressed, content: {
                                WebView(url: URL(string: "https://kenton7.github.io/Serotonika/Privacy")!)
                            })
                            
                            Text("и")
                                .font(.system(size: 9, weight: .light, design: .rounded))
                            
                            Button(action: {
                                isTermsAndConditionsPressed = true
                            }, label: {
                                Text("согласен(-на) с условиями")
                                    .foregroundStyle(.blue)
                                    .font(.system(size: 9, weight: .light, design: .rounded))
                            })
                            .sheet(isPresented: $isTermsAndConditionsPressed, content: {
                                WebView(url: URL(string: "https://kenton7.github.io/Serotonika/Terms")!)
                            })
                            
                            Button(action: {
                                withAnimation {
                                    isAgreeWithPrivacy.toggle()
                                    DispatchQueue.main.async {
                                        self.errorMessage = nil
                                    }
                                }
                            }, label: {
                                RoundedRectangle(cornerRadius: 5, style: RoundedCornerStyle.continuous)
                                    .stroke(activeDarkModel ? .white : .black, lineWidth: 1)
                                    .frame(width: 20, height: 20)
                                    .overlay {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 20))
                                            .foregroundStyle(isAgreeWithPrivacy ? .green : .clear)
                                    }
                            })
                            .padding(.trailing, 1)
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        isRegistration = true
                        Task {
                            do {
                                try await viewModel.asyncRegisterWith(name: name,
                                                                      email: email,
                                                                      password: password)
                                await MainActor.run {
                                    self.isRegistered = true
                                    self.errorMessage = nil
                                }
                            } catch {
                                await MainActor.run {
                                    self.errorMessage = "\(error.localizedDescription)"
                                    self.isRegistration = false
                                }
                            }
                        }
                    }, label: {
                        if isRegistration {
                            LoadingAnimationButton()
                        } else {
                            HStack {
                                Text("Зарегистрироваться")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                            }
                            .contentShape(.rect)
                        }
                    })
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .background(Color(uiColor: .defaultButtonColor))
                    .clipShape(.rect(cornerRadius: 20))
                    .disabled(!email.isValidEmail())
                    .disabled(name.isEmpty)
                    .disabled(password.isEmpty)
                    .disabled(!isAgreeWithPrivacy)
                    .padding(.horizontal)
                    .padding()
                }
            }
            .navigationDestination(isPresented: $isRegistered) {
                WelcomeScreen()
            }
            .onReceive(yandexAuth.$isLoggedIn) { isRegistered in
                if isRegistered {
                    self.isRegistered = true
                }
            }
        }
    }
}


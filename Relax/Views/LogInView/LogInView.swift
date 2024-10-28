//
//  LogInView.swift
//  Relax
//
//  Created by Илья Кузнецов on 21.06.2024.
//

import SwiftUI
import FirebaseAuth
import YandexLoginSDK
import AuthenticationServices
import FirebaseDatabase

struct LogInView: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var isLogIn = false
    @State private var isForgotPasswordPressed = false
    @State private var errorMessage: String?
    @State private var userID: String?
    @State private var userModel: UserModel?
    @State private var isLogining = false
    @StateObject private var databaseVM = ChangeDataInDatabase.shared
    @EnvironmentObject var notificationsService: NotificationsService
    @EnvironmentObject private var yandexViewModel: YandexAuthorization
    private let locale = Locale.current
    @Environment(\.colorScheme) private var scheme
    @State private var isViewed = false
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Image("LoginBackground").ignoresSafeArea()
                    Spacer()
                }
                VStack {
                    Spacer()
                    Text("C возвращением!")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    
                    Button {
                        if let rootViewController = getRootViewController() {
                            DispatchQueue.main.async {
                                self.isLogining = true
                            }
                            do {
                                try YandexLoginSDK.shared.authorize(with: rootViewController, authorizationStrategy: .webOnly)
                            } catch {
                                print("Ошибка запуска авторизации через Яндекс: \(error.localizedDescription)")
                                DispatchQueue.main.async {
                                    self.isLogining = false
                                }
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
                    
                    //Кнопка войти через Apple. НЕ должна быть доступна для пользователей из РФ
                    if locale.identifier != "ru_RU" {
                        SignInWithAppleButton(.signIn) { request in
                            isLogining = true
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = viewModel.currentNonce
                        } onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                Task {
                                    await viewModel.signInWithApple(authorization)
                                }
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                                isLogining = false
                                self.isLogIn = false
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
                    
                    Text("ИЛИ ВОЙТИ С ПОМОЩЬЮ EMAIL")
                        .font(.system(size: 15))
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                    Spacer()
                    
                    VStack {
                        EmailFieldView("Email", email: $email)
                            .padding(.horizontal)
                        PasswordFieldView("Пароль", text: $password)
                            .padding(.horizontal)
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .padding(.horizontal)
                                .bold()
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity)
                                .fixedSize(horizontal: false, vertical: true) // Позволяем тексту расти по вертикали, если необходимо
                        }
                    }
                    
                    Spacer()
                    Button(action: {
                        isLogining = true
                        errorMessage = nil
                        Task.detached {
                            do {
                                try await viewModel.asyncLogInWith(email: email, password: password)
                                if let userID = Auth.auth().currentUser?.uid {
                                    await databaseVM.checkIfFirebaseUserViewedTutorial(userID: userID)
                                }
                                await MainActor.run {
                                    isLogining = false
                                    self.errorMessage = nil
                                    withAnimation {
                                        isLogIn = true
                                    }
                                }
                            } catch {
                                await MainActor.run {
                                    self.errorMessage = "\(error.localizedDescription)"
                                    self.isLogining = false
                                }
                            }
                        }
                    }, label: {
                        if isLogining {
                            LoadingAnimationButton()
                                .frame(width: 40, height: 40)
                        } else {
                            HStack {
                                Text("Войти")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                            }
                            .contentShape(Rectangle())
                        }
                    })
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(uiColor: .defaultButtonColor))
                    .clipShape(.rect(cornerRadius: 20))
                    .padding()
                    .disabled(email.isEmpty)
                    .disabled(password.isEmpty)
                    .padding(.horizontal)
                    .padding()
                    
                    Button(action: {
                        withAnimation {
                            isForgotPasswordPressed = true
                        }
                    }, label: {
                        Text("Забыли пароль?")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .darkGray))
                    })
                    .padding()
                }
            }
        }
        .navigationDestination(isPresented: $isLogIn) {
            if isViewed {
                CustomTabBar()
                    .navigationBarBackButtonHidden()
            } else {
                WelcomeScreen()
            }
        }
        .onReceive(databaseVM.$isTutorialViewed) { isViewed in
            self.isViewed = isViewed
            self.isLogIn = true
        }
        .onChange(of: databaseVM.isTutorialViewed) { newValue in
            isViewed = newValue
            isLogIn = true
        }
        .onChange(of: yandexViewModel.isLoggedIn) { newValue in
            if newValue {
                isLogIn = true
            }
        }
        .navigationDestination(isPresented: $isForgotPasswordPressed) {
            ForgotPasswordView()
        }
        .onAppear {
            email = ""
            password = ""
            isLogIn = false
        }
    }
}


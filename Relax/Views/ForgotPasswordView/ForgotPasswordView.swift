//
//  ForgotPasswordView.swift
//  Relax
//
//  Created by Илья Кузнецов on 21.06.2024.
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var hasSentRestorePassword = false
    @State private var isErrorWhenRestore = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            Text("Введите электронную почту, на которую зарегистрирован ваш аккаунт")
                .padding()
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            Spacer()
            EmailFieldView("Email", email: $email)
            Spacer()
            Button(action: {
                authViewModel.restorePasswordWith(email: email) { success, error in
                    if success {
                        hasSentRestorePassword = true
                    } else {
                        if let error = error {
                            //_ = AuthErrorCode(_nsError: error)
                            isErrorWhenRestore = true
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }, label: {
                Text("Сбросить пароль")
                    .foregroundStyle(.white)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            })
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .defaultButtonColor))
            .clipShape(.rect(cornerRadius: 20))
            .padding()
            .disabled(email.isEmpty)
            .alert("На вашу почту были отправлены инструкции для сброса пароля. Пожалуйста, проверьте.", isPresented: $hasSentRestorePassword) {
                VStack {
                    Button("OK", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .alert(errorMessage, isPresented: $isErrorWhenRestore) {
                Button("ОК", role: .destructive) {}
            } message: {
                Text("Произошла ошибка при попытке восстановления пароля. Пожалуйста, повторите попытку или свяжитесь с нами: serotonika.app@gmail.com")
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}

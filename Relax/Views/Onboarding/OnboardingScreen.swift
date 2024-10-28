//
//  OnboardingScreen.swift
//  Relax
//
//  Created by Илья Кузнецов on 21.06.2024.
//

import SwiftUI

struct OnboardingScreen: View {
    
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var hasAccount = false
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Image("Frame").ignoresSafeArea()
                        .scaleEffect(CGSize(width: 1.2, height: 1.0))
                    Spacer()
                }
                VStack {
                    Text("Серотоника")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                    OnboardingAnimation()
                        .frame(width: 200, height: 200)
                    Spacer()
                    Text("Привет!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .padding(.bottom)
                    Text("Добро пожаловать в наше приложение для медитации! Мы здесь, чтобы помочь вам найти внутренний покой и гармонию. Наши специально разработанные медитации и упражнения направлены на улучшение вашего самочувствия, снижение стресса и повышение концентрации. Начните свой путь к спокойствию и самосовершенствованию уже сегодня!")
                        .padding(.horizontal)
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundStyle(Color(uiColor: .gray))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    NavigationLink {
                        RegisterView()
                    } label: {
                        Text("Зарегистрироваться")
                            .foregroundStyle(.white)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .padding()
                    .background(Color(uiColor: .defaultButtonColor))
                    .clipShape(.rect(cornerRadius: 20))
                    .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text("Уже есть аккаунт?")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Button {
                            hasAccount = true
                        } label: {
                            Text("Войти")
                                .foregroundStyle(.blue)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.blue)
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationDestination(isPresented: $hasAccount) {
            LogInView()
        }
    }
}

#Preview {
    OnboardingScreen()
}

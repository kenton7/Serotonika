//
//  PremiumScreen.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 24.08.2024.
//

import SwiftUI
import StoreKit

struct PremiumScreen: View {
    
    @EnvironmentObject private var premuimViewModel: PremiumViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var isRestoringPurchases = false
    @State private var isPrivacyPolicyPressed = false
    @State private var isTermsAndConditionsPressed = false
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    
    var body: some View {
        Group {
            if premuimViewModel.purchasedSubscriptions.isEmpty {
                PremuimView()
            } else {
                ThanksForPremiumView()
            }
        }
        .preferredColorScheme(activeDarkModel ? .dark : .light)
    }
//        .onAppear {
//            Task {
//                do {
//                    try await premuimViewModel.loadProducts()
//                    await MainActor.run {
//                        self.isLoading = false
//                    }
//                } catch {
//                    print("error loading products \(error)")
//                }
//            }
//        }
//        .task {
//            do {
//                try await premuimViewModel.loadProducts()
//                await MainActor.run {
//                    self.isLoading = false
//                }
//            } catch {
//                print("error loading products \(error)")
//            }
//        }
//    }
}

struct ThanksForPremiumView: View {
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        withAnimation {
            VStack(spacing: 20) {
                Text("Добро пожаловать в мир спокойствия!")
                    .padding()
                    .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                     green: 65/255,
                                                                                     blue: 78/255,
                                                                                     alpha: 1)))
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                CompletePurchaseAnimation()
                    .frame(width: 150, height: 100)
                    .padding()
                
                Group {
                    Text("""
                    Спасибо за вашу подписку на Серотонику! 
                    Теперь у вас есть полный доступ ко всем медитациям, урокам и персонализированным программам. Вы сделали важный шаг на пути к внутреннему покою и благополучию.

                    Мы рады, что вы с нами! 
                    Если у вас возникнут вопросы или нужна помощь, наша команда всегда готова помочь. Наслаждайтесь каждым моментом с Серотоникой!
                    """)
                }
                .padding(.horizontal)
                .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255, green: 65/255, blue: 78/255, alpha: 1)))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .multilineTextAlignment(.leading)

                
                Button(action: {
                    dismiss()
                }, label: {
                    HStack {
                        Text("Закрыть")
                            .foregroundStyle(.white)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                    }
                    .contentShape(.rect)
                })
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(uiColor: .defaultButtonColor))
                .clipShape(.rect(cornerRadius: 20))
                .padding()
            }
        }
    }
}

struct PremuimView: View {
    
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var premuimViewModel: PremiumViewModel
    @State private var isLoading = true
    @State private var isRestoringPurchases = false
    @State private var isPrivacyPolicyPressed = false
    @State private var isTermsAndConditionsPressed = false
    
    var body: some View {
        PremiumAnimation()
            .frame(height: 150)
        Group {
            Text("Разблокируйте все возможности!")
                .padding(.horizontal)
                .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 161/255,
                                                                                 green: 164/255,
                                                                                 blue: 178/255,
                                                                                 alpha: 1)))
            VStack {
                HStack {
                    Image(systemName: "checkmark.square.fill")
                        .foregroundStyle(.green)
                        .frame(width: 15, height: 15)
                    Text("Неограниченные медитации: открывайте для себя новые практики каждый день;")
                        .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                         green: 65/255,
                                                                                         blue: 78/255,
                                                                                         alpha: 1)))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }
                .padding(.horizontal)
                
                HStack {
                    Image(systemName: "checkmark.square.fill")
                        .foregroundStyle(.green)
                        .frame(width: 15, height: 15)
                    Text("Эксклюзивные материалы: глубокие уроки по осознанности, управлению стрессом и улучшению сна;")
                        .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                         green: 65/255,
                                                                                         blue: 78/255,
                                                                                         alpha: 1)))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }
                .padding(.horizontal)
                
                HStack {
                    Image(systemName: "checkmark.square.fill")
                        .foregroundStyle(.green)
                        .frame(width: 15, height: 15)
                    Text("Скачивайте уроки или весь плейлист в оффлайн: практикуйтесь даже там, где нет интернета.")
                        .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                         green: 65/255,
                                                                                         blue: 78/255,
                                                                                         alpha: 1)))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(5)
            
            VStack {
                Text("Выберите свой план:")
                    .padding()
                    .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                     green: 65/255,
                                                                                     blue: 78/255,
                                                                                     alpha: 1)))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                    ForEach(premuimViewModel.subscriptions) { product in
                        Button(action: {
                            Task {
                                do {
                                    let _ = try await premuimViewModel.purchase(product)
                                    print("Покупка успешна для продукта \(product.displayName)")
                                } catch {
                                    print("Ошибка при покупке: \(error.localizedDescription)")
                                }
                            }
                        }, label: {
                            HStack {
                                Text("\(product.displayPrice) / \(product.displayName)")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                            }
                            .contentShape(.rect)
                        })
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(Color(uiColor: .defaultButtonColor))
                        .clipShape(.rect(cornerRadius: 20))
                        .padding(.horizontal)
                    }
            }
            //.padding(.bottom)
            
            Button(action: {
                isRestoringPurchases = true
                    Task {
                        do {
                            try await AppStore.sync()
                            print("Покупки восстановлены")
                            await MainActor.run {
                                self.isRestoringPurchases = false
                            }
                        } catch {
                            print("Ошибка при восстановлении покупок: \(error.localizedDescription)")
                            isRestoringPurchases = false
                        }
                    }
            }, label: {
                if isRestoringPurchases {
                    LoadingAnimationButton()
                        .frame(width: 40, height: 40)
                } else {
                    Text("Восстановить покупки").bold()
                        .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                         green: 65/255,
                                                                                         blue: 78/255,
                                                                                         alpha: 1)))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
            })
            .padding(.top)
            
            Text("Оплата будет снята с вашего аккаунта App Store после подтверждения покупки. Подписка автоматически продлевается. Управление подпиской и отключение автообновления доступны в настройках вашего аккаунта App Store.")
                .padding(10)
                .foregroundStyle(Color(uiColor: .secondaryTextColor))
                .font(.system(size: 11, weight: .light, design: .rounded))
            
            VStack {
                Text("Оформляя подписку, вы даёте согласие на")
                    .padding(.leading, 1)
                    .font(.system(size: 9, weight: .light, design: .rounded))
                
                HStack(spacing: 3) {
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
                        Text("условия использования")
                            .foregroundStyle(.blue)
                            .font(.system(size: 9, weight: .light, design: .rounded))
                    })
                    .sheet(isPresented: $isTermsAndConditionsPressed, content: {
                        WebView(url: URL(string: "https://kenton7.github.io/Serotonika/Terms")!)
                    })
                }
            }
        }
        Spacer()
    }
}

//
//  ProfileScreen.swift
//  Relax
//
//  Created by Илья Кузнецов on 02.07.2024.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
import StoreKit

enum ProfileScreenModel: String, CaseIterable {
    case account = "Аккаунт"
    case notifications = "Уведомления"
    case downloaded = "Скачанное"
    case buyPremium = "Премиум"
    case writeDevelopers = "Связаться с разработчиком"
    case aboutUs = "О нас"
    case restorePurchases = "Восстановить покупки"
}

enum NavigationDestination: Hashable {
    case accountScreen
    case notifications
    case downloaded
}

struct ProfileScreen: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject private var yandexViewModel: YandexAuthorization
    @EnvironmentObject private var premiumViewModel: PremiumViewModel
    private var currentUser = Auth.auth().currentUser
    @State private var isBuyPremiumPressed = false
    @State private var aboutUsPressed = false
    @State private var isRemindersPressed = false
    @State private var userName = ""
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    @State private var buttonRect: CGRect = .zero
    @State private var currentStateImage: UIImage?
    @State private var previousStateImage: UIImage?
    @State private var maskAnimation: Bool = false
    @State private var isProfile = true
    let fileManagerService: IFileManagerSerivce = FileManagerSerivce()
    @EnvironmentObject private var emailService: EmailService
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                List {
                    Section("Настройки") {
                        NavigationLink {
                            AccountScreen()
                                .onAppear {
                                    isProfile = false
                                }
                        } label: {
                            HStack {
                                Image("account")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("Аккаунт")
                            }
                        }
                        
                        NavigationLink {
                            RemindersScreen(isFromSettings: true)
                                .onAppear {
                                    isProfile = false
                                }
                        } label: {
                            HStack {
                                Image("notifications")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("Уведомления")
                            }
                        }
                        
                        Button(action: {
                            isBuyPremiumPressed = true
                        }, label: {
                            HStack {
                                Image("premium")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("Премиум")
                            }
                        })
                        .sheet(isPresented: $isBuyPremiumPressed, content: {
                            PremiumScreen()
                                .onAppear {
                                    isProfile = false
                                }
                        })
                    }
                    
                    Section("Материалы") {
                        NavigationLink {
                            if premiumViewModel.hasUnlockedPremuim {
                                DownloadedScreen(fileManagerSerivce: fileManagerService)
                                    .onAppear {
                                        isProfile = false
                                    }
                            } else {
                                PremiumScreen()
                                    .onAppear {
                                        isProfile = false
                                    }
                            }
                        } label: {
                            HStack {
                                Image("downloaded")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("Скачанное")
                            }
                        }
                        
                        NavigationLink {
                            UserLikedPlaylistsScreen()
                                .onAppear {
                                    isProfile = false
                                }
                        } label: {
                            HStack {
                                Image("like")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("Вам понравилось")
                            }
                        }
                        
                    }
                    
                    Section("Помощь") {
                        Button(action: {
                            emailService.openMail(emailTo: "serotonika.app@gmail.com",
                                                  subject: "Серотоника",
                                                  body: "Версия: \(Bundle.main.appVersion), сборка: \(Bundle.main.appBuild)")
                        }, label: {
                            HStack {
                                Image("email")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("Связаться с разработчиком")
                                
                            }
                        })
                        
                        //                        Button(action: {
                        //                            aboutUsPressed = true
                        //                        }, label: {
                        //                            HStack {
                        //                                Image("aboutUs")
                        //                                    .resizable()
                        //                                    .frame(width: 20, height: 20)
                        //                                Text("О нас")
                        //                            }
                        //                        })
                        //                        .sheet(isPresented: $aboutUsPressed, content: {
                        //                            WebView(url: URL(string: "https://firebasestorage.googleapis.com/v0/b/relax-8e1d3.appspot.com/o/aboutUs.rtf?alt=media&token=64393fb2-c94c-4f6b-a904-1688cb4c2a65")!)
                        //                                .ignoresSafeArea()
                        //                                .navigationTitle("О нас")
                        //                                .navigationBarTitleDisplayMode(.inline)
                        //                        })
                    }
                    
                    Button(action: {
                        Task {
                            do {
                                try await AppStore.sync()
                            } catch {
                                print("Error when restoring purchases \(error)")
                            }
                        }
                    }, label: {
                        HStack {
                            Image("restorePurchases")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Восстановить покупки")
                        }
                    })
                }
                .scrollIndicators(.hidden)
                .foregroundStyle(toogleDarkMode ? .white : .black)
                .font(.system(size: 20, weight: .regular, design: .rounded))
                
                //                VStack {
                //                     Text("Версия: \(Bundle.main.appVersion)")
                //                     Text("Сборка: \(Bundle.main.appBuild)")
                //                 }
                //                 .padding()
                //                 .foregroundStyle(Color(uiColor: .secondaryTextColor))
                //                 .font(.system(size: 12, weight: .light, design: .rounded))
                //                 .padding(.bottom)
            }
            .onAppear {
                isProfile = true
            }
            .font(.system(size: 20, weight: .regular, design: .rounded))
            .navigationTitle(userName)
        }
        .tint(activeDarkModel ? .white : .black)
        .onAppear {
            if let userName = Auth.auth().currentUser?.displayName {
                self.userName = userName
            } else {
                self.userName = yandexViewModel.userName ?? ""
            }
        }
        .createImages(toogleDarkMode: toogleDarkMode,
                      currentImage: $currentStateImage,
                      previousImage: $previousStateImage,
                      activateDarkMode: $activeDarkModel)
        //Логика кнопки смены темы
        .overlay {
            if isProfile {
                GeometryReader(content: { geometry in
                    let size = geometry.size
                    if let previousStateImage, let currentStateImage {
                        ZStack {
                            Image(uiImage: previousStateImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: size.width, height: size.height)
                            
                            Image(uiImage: currentStateImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: size.width, height: size.height)
                                .mask(alignment: .topLeading) {
                                    Circle()
                                        .frame(width: buttonRect.width * (maskAnimation ? 80 : 1), height: buttonRect.height * (maskAnimation ? 80 : 1), alignment: .bottomLeading)
                                        .frame(width: buttonRect.width, height: buttonRect.height)
                                        .offset(x: buttonRect.minX, y: buttonRect.minY)
                                        .ignoresSafeArea()
                                }
                        }
                        .task {
                            guard !maskAnimation else { return }
                            if #available(iOS 17.0, *) {
                                withAnimation(.easeInOut(duration: 0.9), completionCriteria: .logicallyComplete) {
                                    maskAnimation = true
                                } completion: {
                                    self.currentStateImage = nil
                                    self.previousStateImage = nil
                                    maskAnimation = false
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.9)) {
                                    self.currentStateImage = nil
                                    self.previousStateImage = nil
                                    maskAnimation = false
                                }
                            }
                            
                        }
                    }
                })
                .mask({
                    Rectangle()
                        .overlay(alignment: .topLeading) {
                            Circle()
                                .frame(width: buttonRect.width, height: buttonRect.height)
                                .offset(x: buttonRect.minX, y: buttonRect.minY)
                                .blendMode(.destinationOut)
                        }
                })
                .ignoresSafeArea()
            }
        }
        .overlay(alignment: .topTrailing) {
            if isProfile {
            if #available(iOS 17.0, *) {
                Button(action: {
                    toogleDarkMode.toggle()
                }, label: {
                    Image(systemName: toogleDarkMode ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(toogleDarkMode ? .white : .primary)
                        .symbolEffect(.bounce, value: toogleDarkMode)
                        .frame(width: 40, height: 40)
                })
                .rect { rect in
                    buttonRect = rect
                }
                .padding(10)
            } else {
                Button(action: {
                    toogleDarkMode.toggle()
                }, label: {
                    Image(systemName: toogleDarkMode ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                })
                .rect { rect in
                    buttonRect = rect
                }
                .padding(10)
                .disabled(currentStateImage != nil || previousStateImage != nil || maskAnimation)
            }
        }
    }
            .preferredColorScheme(activeDarkModel ? .dark : .light)
            .overlay(alignment: .bottom) {
                if isProfile {
                HStack {
                    Text("Версия: \(Bundle.main.appVersion), сборка: \(Bundle.main.appBuild)")
                    //Text("Сборка: \(Bundle.main.appBuild)")
                }
                .padding()
                .foregroundStyle(Color(uiColor: .secondaryTextColor))
                .font(.system(size: 12, weight: .light, design: .rounded))
                .padding(.bottom)
            }
        }
    }
}

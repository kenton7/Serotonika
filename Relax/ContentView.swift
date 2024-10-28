//
//  ContentView.swift
//  Relax
//
//  Created by Илья Кузнецов on 21.06.2024.
//

import SwiftUI
import CoreData
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase

enum LoadingState {
    case loading
    case signedIn
    case onboarding
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var yandexViewModel = YandexAuthorization.shared
    @EnvironmentObject var databaseVM: ChangeDataInDatabase
    @EnvironmentObject var notificationsService: NotificationsService
    
    @State private var isLoading = true
    @State private var isViewed = false
    
    var body: some View {
        
        Group {
            if isLoading {
                LoadingAnimation()
            } else if (authViewModel.signedIn || yandexViewModel.isLoggedIn) && databaseVM.isTutorialViewed {
                CustomTabBar()
                    .navigationBarBackButtonHidden()
            } else {
                NavigationStack {
                    OnboardingScreen()
                }
            }
        }
        .onAppear {
            authViewModel.signedIn = authViewModel.isUserLoggedIn
        }
        .task {
            if let firebaseUserID = Auth.auth().currentUser?.uid {
                isViewed = await databaseVM.checkIfUserViewedTutorial(userID: firebaseUserID)
                databaseVM.isTutorialViewed = isViewed
                await MainActor.run {
                    isLoading = false
                    authViewModel.signedIn = authViewModel.isUserLoggedIn
                }
            } else if yandexViewModel.userToken != nil {
                if let _ = yandexViewModel.userInfo {
                    isViewed = await databaseVM.checkIfUserViewedTutorial(userID: yandexViewModel.yandexUserID)
                    await MainActor.run {
                        isLoading = false
                        yandexViewModel.isLoggedIn = yandexViewModel.isUserLoggedWithYandex
                    }
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
        .onChange(of: yandexViewModel.isLoggedIn) { newValue in
            if newValue {
                Task {
                    isViewed = await databaseVM.checkIfUserViewedTutorial(userID: yandexViewModel.yandexUserID)
                    await MainActor.run {
                        self.isLoading = false
                        yandexViewModel.isLoggedIn = yandexViewModel.isUserLoggedWithYandex
                    }
                }
            }
        }
    }
}

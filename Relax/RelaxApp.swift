//
//  RelaxApp.swift
//  Relax
//
//  Created by Илья Кузнецов on 21.06.2024.
//

import SwiftUI
import FirebaseCore
import CoreData
import AVFoundation
import YandexLoginSDK
import RevenueCat

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        setupAudioSession()
        
        do {
            try YandexLoginSDK.shared.activate(with: .yandexLoginSDKClientID, authorizationStrategy: .default)
        } catch {
            print("yandex login error: \(error)")
        }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        do {
            try YandexLoginSDK.shared.handleOpenURL(url)
        } catch {
            print("error open URL: \(error)")
        }
        
        return true
    }
    
    private func setupAudioSession() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure AVAudioSession in AppDelegate: \(error.localizedDescription)")
        }
    }
    
    func application(
            _ application: UIApplication,
            continue userActivity: NSUserActivity,
            restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
        ) -> Bool {
        
            do {
                try YandexLoginSDK.shared.handleUserActivity(userActivity)
            } catch {
                print("error user activity: \(error)")
            }
            return true
        }
}

@main
struct RelaxApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var playerViewModel = PlayerViewModel.shared
    @StateObject private var nightStoriesVM = NightStoriesViewModel()
    @StateObject private var meditationViewModel = CoursesViewModel()
    @StateObject private var yandexViewModel = YandexAuthorization.shared
    @StateObject private var notificationsService = NotificationsService.shared
    @StateObject private var changeDatabase = ChangeDataInDatabase.shared
    @StateObject private var premuimViewModel = PremiumViewModel.shared
    @StateObject private var downloadManager = DownloadManager()
    @StateObject private var navigationService = NavigationService()
    let persistenceController = PersistenceController.shared
    

    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(playerViewModel)
                .environmentObject(nightStoriesVM)
                .environmentObject(meditationViewModel)
                .environmentObject(notificationsService)
                .environmentObject(changeDatabase)
                .environmentObject(yandexViewModel)
                .environmentObject(premuimViewModel)
                .environmentObject(downloadManager)
                .environmentObject(navigationService)
//                .task {
//                    await premuimViewModel.updatePurchasedProducts()
//                }
                .environment(\.colorScheme, activeDarkModel ? .dark : .light)
                //.environment(\.colorScheme, .light)
        }
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}


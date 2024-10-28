//
//  GreetingView.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 21.10.2024.
//

import SwiftUI

//MARK: - GreetingView
struct GreetingView: View {
    
    @StateObject private var homeScreenViewModel = HomeScreenViewModel()
    @EnvironmentObject var yandexViewModel: YandexAuthorization
    @Binding var isShowing: Bool
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        VStack {
            HStack {
                Text(homeScreenViewModel.greeting)
                    .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                     green: 65/255,
                                                                                     blue: 78/255,
                                                                                     alpha: 1)))
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                Spacer()
            }
            
            HStack {
                Text(homeScreenViewModel.secondaryGreeting)
                    .font(.system(size: 13, weight: .light, design: .rounded))
                    .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 161/255,
                                                                                     green: 164/255,
                                                                                     blue: 178/255,
                                                                                     alpha: 1)))
                Spacer()
            }
        }
        .padding()
        .offset(y: isShowing ? 0 : -200)
        .animation(.bouncy, value: isShowing)
        .onAppear {
            homeScreenViewModel.updateGreeting()
        }
    }
}

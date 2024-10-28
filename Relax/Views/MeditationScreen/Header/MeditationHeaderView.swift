//
//  MeditationHeaderView.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 21.10.2024.
//

import SwiftUI

//MARK: - MeditationHeaderView
struct MeditationHeaderView: View {
    
    @Binding var isShowing: Bool
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        VStack {
            Text("Погрузитесь в мир осознанности и внутреннего спокойствия с нашими подробными уроками медитации, созданными для всех уровней подготовки.")
                .padding()
                .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 160/255,
                                                                                 green: 163/255,
                                                                                 blue: 177/255,
                                                                                 alpha: 1)))
                .font(.system(size: 20, weight: .light, design: .rounded))
                .multilineTextAlignment(.center)
                .offset(x: isShowing ? 0 : -1000)
                .animation(.bouncy, value: isShowing)
        }
        .padding(.vertical)
    }
}

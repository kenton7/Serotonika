//
//  HeaderModifier.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 25.10.2024.
//

import SwiftUI

struct ScrollPreKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HeaderModifier: ViewModifier {
    @Binding var isScrolling: Bool
    var title: String
    @Binding var activeDarkModel: Bool
    @Binding var isShowing: Bool
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top) {
                Color.clear
                    .frame(height: 30)
            }
            .overlay(alignment: .top) {
                GeometryReader { proxy in
                    ZStack {
                        Color.clear
                            .frame(height: isScrolling ? proxy.size.height * 0.06 : proxy.size.height * 0.08)
                            .background(.ultraThinMaterial)
                            .blur(radius: 0.5)
                            //.edgesIgnoringSafeArea(.top)
                        HStack {
                            Text(title)
                                .font(.system(size: isScrolling ? 15 : 25, weight: .bold, design: .rounded))
                                .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255, green: 65/255, blue: 78/255, alpha: 1)))
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.top)
                        .offset(y: -13)
                    }
                    .frame(maxHeight: .infinity, alignment: .top) // Задаёт позицию слоя по верхней части экрана
                }
                //.edgesIgnoringSafeArea(.top)
                
//                ZStack {
//                    Color.clear
//                        .frame(height: isScrolling ? 80 : 100)
//                        .opacity(isScrolling ? 1 : 0)
//                        .background(.ultraThinMaterial)
//                        .blur(radius: 0.5)
//                        .edgesIgnoringSafeArea(.top)
//                    HStack {
//                        Text(title)
//                            .padding(.bottom, 10)
//                            .padding(.horizontal)
//                            .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
//                                                                                             green: 65/255,
//                                                                                             blue: 78/255,
//                                                                                             alpha: 1)))
//                            .font(.system(size: isScrolling ? 15 : 25, weight: .bold, design: .rounded))
//                            .offset(y: isShowing ? 0 : -1000)
//                            .animation(.bouncy, value: isShowing)
//                    }
//                    .offset(y: isScrolling ? -30 : -25)
//                }
//                .frame(maxHeight: .infinity, alignment: .top)
            }
//            .safeAreaInset(edge: .top) {
//                Color.clear.frame(height: 10) // Отступ для безопасной зоны
//            }
    }
}

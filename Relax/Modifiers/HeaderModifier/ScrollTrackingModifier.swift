//
//  ScrollTrackingModifier.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 25.10.2024.
//

import SwiftUI

struct ScrollTrackingModifier: ViewModifier {
    @Binding var isScrolling: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.frame(in: .global).minY) { newValue in
                            withAnimation(.default) {
                                isScrolling = newValue < 20
                            }
                        }
                }
            )
    }
}




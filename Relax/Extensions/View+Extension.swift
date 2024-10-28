//
//  View+Extension.swift
//  Relax
//
//  Created by Илья Кузнецов on 26.07.2024.
//

import Foundation
import SwiftUI

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    func getRootViewController() -> UIViewController? {
            guard let windowScene = UIApplication.shared.connectedScenes
                    .first as? UIWindowScene else {
                return nil
            }
            return windowScene.windows.first?.rootViewController
        }
    
    @ViewBuilder
    func rect(value: @escaping (CGRect) -> Void) -> some View {
        self
            .overlay {
                GeometryReader(content: { geometry in
                    let rect = geometry.frame(in: .global)
                    Color.clear
                        .preference(key: RectKey.self, value: rect)
                        .onPreferenceChange(RectKey.self, perform: { rect in
                            value(rect)
                        })
                })
            }
    }
    
    @MainActor
    @ViewBuilder
    func createImages(toogleDarkMode: Bool,
                      currentImage: Binding<UIImage?>,
                      previousImage: Binding<UIImage?>,
                      activateDarkMode: Binding<Bool>) -> some View {
        self
            .onChange(of: toogleDarkMode) { newValue in
                Task {
                    if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) {
                        let imageView = UIImageView()
                        imageView.frame = window.frame
                        imageView.image = window.rootViewController?.view.image(window.frame.size)
                        imageView.contentMode = .scaleAspectFit
                        window.addSubview(imageView)
                        
                        if let rootView = window.rootViewController?.view {
                            let frameSize = rootView.frame.size
                            activateDarkMode.wrappedValue = !newValue
                            previousImage.wrappedValue = rootView.image(frameSize)
                            activateDarkMode.wrappedValue = newValue
                            try await Task.sleep(for: .seconds(0.1))
                            currentImage.wrappedValue = rootView.image(frameSize)
                            try await Task.sleep(for: .seconds(0.1))
                            imageView.removeFromSuperview()
                        }
                    }
                }
            }
    }
}

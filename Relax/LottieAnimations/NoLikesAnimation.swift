//
//  NoLikesAnimation.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 27.10.2024.
//

import Foundation
import Lottie
import SwiftUI
import UIKit

struct NoLikesAnimation: UIViewRepresentable {
    
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    init() {
        emptyText.textColor = activeDarkModel ? .white : .black
    }
    
    private let onboardingAnimation: LottieAnimationView = {
       let animation = LottieAnimationView()
        animation.animation = LottieAnimation.named("NoLikesAnimation")
        animation.translatesAutoresizingMaskIntoConstraints = false
        animation.contentMode = .scaleAspectFit
        animation.loopMode = .loop
        animation.animationSpeed = 0.5
        animation.play()
        return animation
    }()
    
    private let emptyText: UILabel = {
       let label = UILabel()
        label.text = "Вы пока что не ставили лайки.\nЛайкайте плейлисты и они все появятся здесь."
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.numberOfLines = 3
        label.textAlignment = .center
        return label
    }()
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        view.addSubview(onboardingAnimation)
        view.addSubview(emptyText)
        NSLayoutConstraint.activate([
            onboardingAnimation.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            onboardingAnimation.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            onboardingAnimation.heightAnchor.constraint(equalToConstant: 200),
            onboardingAnimation.widthAnchor.constraint(equalToConstant: 200),
            emptyText.topAnchor.constraint(equalTo: onboardingAnimation.bottomAnchor, constant: 10),
            emptyText.centerXAnchor.constraint(equalTo: onboardingAnimation.centerXAnchor),
            emptyText.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

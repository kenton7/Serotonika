//
//  EmptyAnimation.swift
//  Relax
//
//  Created by Илья Кузнецов on 31.07.2024.
//

import Foundation
import Lottie
import SwiftUI
import UIKit

struct EmptyAnimation: UIViewRepresentable {
    
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    init() {
        emptyText.textColor = activeDarkModel ? .white : .black
    }
    
    private let onboardingAnimation: LottieAnimationView = {
       let animation = LottieAnimationView()
        animation.animation = LottieAnimation.named("EmptyAnimation")
        animation.translatesAutoresizingMaskIntoConstraints = false
        animation.contentMode = .scaleAspectFit
        animation.loopMode = .loop
        animation.animationSpeed = 0.5
        animation.play()
        return animation
    }()
    
    private let emptyText: UILabel = {
       let label = UILabel()
        label.text = "Вы пока ничего не скачивали"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .bold)
        //label.textColor = .black
        return label
    }()
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        view.addSubview(onboardingAnimation)
        view.addSubview(emptyText)
        NSLayoutConstraint.activate([
            onboardingAnimation.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            onboardingAnimation.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyText.topAnchor.constraint(equalTo: onboardingAnimation.bottomAnchor, constant: 10),
            emptyText.centerXAnchor.constraint(equalTo: onboardingAnimation.centerXAnchor)
        ])
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

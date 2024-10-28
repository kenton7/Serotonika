//
//  AVPlayerRepresentable.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 24.10.2024.
//

import Foundation
import SwiftUI
import UIKit
import AVKit


class VideoPlayerController: UIViewController {
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let videoURL = URL(fileURLWithPath: Bundle.main.path(forResource: "PlayerVideo1", ofType: "mp4")!)
        player = AVPlayer(url: videoURL)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem)

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(playerLayer)

        player?.play()
    }

    @objc private func playerDidFinishPlaying(notification: Notification) {
        // Перезапускаем видео при окончании воспроизведения
        player?.seek(to: .zero)
        player?.play()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct AVPlayerControllerRepresented: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> VideoPlayerController {
        return VideoPlayerController()
    }

    func updateUIViewController(_ uiViewController: VideoPlayerController, context: Context) {}
}



//
//  PlayerScreen.swift
//  Relax
//
//  Created by Илья Кузнецов on 05.07.2024.
//

import SwiftUI
import FirebaseDatabase
import AVFoundation
import FirebaseAuth
import StoreKit
import _AVKit_SwiftUI

struct PlayerScreen: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) var requestReview
    @State private var sliderValue: Double = 0.0
    @ObservedObject private var fetchDatabaseVM = CoursesViewModel()
    @StateObject private var databaseVM = ChangeDataInDatabase.shared
    @StateObject private var playerViewModel = PlayerViewModel.shared
    @EnvironmentObject private var yandexViewModel: YandexAuthorization
    @EnvironmentObject private var premiumViewModel: PremiumViewModel
    @EnvironmentObject private var downloadManager: DownloadManager
    @State private var errorDownloadingMessage = ""
    @State private var isDowndloadError = false
    @State private var isDownloaded = false
    private let currentUser = Auth.auth().currentUser
    private let fileManagerService: IFileManagerSerivce = FileManagerSerivce()
    @State private var isPressedDownloadWithoutPremium = false
    @State private var isListenersUpdated: Bool?
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    
    let lesson: Lesson?
    let isFemale: Bool
    let course: CourseAndPlaylistOfDayModel
    @State var url: String
    //var videoPlayer: AVPlayer
    
    private let videoURL = URL(fileURLWithPath: Bundle.main.path(forResource: "PlayerVideo1", ofType: "mp4")!)
    
    var body: some View {
        ZStack {
            // Видео на заднем плане
            Group {
                AVPlayerControllerRepresented()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .scaleEffect(x: 1.5, y: 1.5)
            }
//            if course.type == .story {
//                Color(uiColor: .init(red: 3/255, green: 23/255, blue: 76/255, alpha: 1)).ignoresSafeArea()
//            } else {
//                if activeDarkModel {
//                    Color(uiColor: .init(red: 41/255,
//                                         green: 42/255,
//                                         blue: 47/255,
//                                         alpha: 1))
//                        .ignoresSafeArea()
//                } else {
//                    Color(uiColor: .init(red: 250/255,
//                                         green: 247/255,
//                                         blue: 242/255,
//                                         alpha: 1))
//                    .ignoresSafeArea()
//                }
//            }
            VStack {
                HStack {
                    Button(action: {
                        let impactMed = UIImpactFeedbackGenerator(style: .soft)
                        impactMed.impactOccurred()
                        dismiss()
                    }, label: {
                        Image("CloseButton")
                    })
                    .padding()
                    Spacer()
                    
                    if let lesson {
                        HStack {
                            Spacer()
                            if !isDownloaded {
                                Button(action: {
                                    if premiumViewModel.hasUnlockedPremuim {
                                        isPressedDownloadWithoutPremium = false
                                        Task.detached {
                                            do {
                                                let _ = try await downloadManager.downloadLesson(course: course,
                                                                                           courseType: course.type,
                                                                                           isFemale: isFemale,
                                                                                           lesson: lesson)
                                                await MainActor.run {
                                                    withAnimation {
                                                        self.isDownloaded = true
                                                    }
                                                }
                                            } catch {
                                                await MainActor.run {
                                                    self.isDowndloadError = true
                                                    self.errorDownloadingMessage = error.localizedDescription
                                                }
                                            }
                                        }
                                    } else {
                                        isPressedDownloadWithoutPremium = true
                                    }
                                }, label: {
                                    Image("DownloadButton")
                                })
                                .padding()
                                .overlay {
                                    if !isDownloaded {
                                        ZStack {
                                            Circle()
                                                .stroke(Color.gray, lineWidth: 4)
                                                .padding()
                                            Circle()
                                                .trim(from: 0, to: downloadManager.totalProgress / 100)
                                                .stroke(Color.green, lineWidth: 4)
                                                .padding()
                                                .rotationEffect(.degrees(-90))
                                        }
                                        .opacity(downloadManager.totalProgress >= 100 ? 0 : 1)
                                    }
                                }
                                .alert("Ошибка при скачивании файла", isPresented: $isDowndloadError) {
                                    HStack {
                                        Button("ОК", role: .cancel) {}
                                    }
                                } message: {
                                    Text(errorDownloadingMessage)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                VStack {
                    Spacer()
                    Text((playerViewModel.lessonName == "" ? lesson?.name : playerViewModel.lessonName) ?? "")
                        .foregroundStyle(course.type == .story || activeDarkModel ? .white : .black)
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(course.name)
                        .font(.system(size: 17, weight: .light, design: .rounded))
                        .foregroundStyle(Color(uiColor: .init(red: 160/255,
                                                              green: 163/255,
                                                              blue: 177/255,
                                                              alpha: 1)))
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                VStack {
                    HStack(spacing: 60) {
                        Button(action: {
                            playerViewModel.seek(by: -15) { isPremium in
                                if !isPremium && playerViewModel.currentTrackIndex > 0 {
                                    isPressedDownloadWithoutPremium = true
                                }
                            }
                        }, label: {
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 35))
                                .foregroundStyle(course.type == .story || activeDarkModel ? .white : .gray)
                        })
                        
                        Button(action: {
                            let impactMed = UIImpactFeedbackGenerator(style: .soft)
                            impactMed.impactOccurred()
                            if lesson != nil {
                                //let url = isFemale ? lesson.audioFemaleURL : lesson.audioMaleURL
                                Task {
                                    let lessons = await fetchDatabaseVM.fetchCourseDetails(type: course.type,
                                                                                           courseID: course.id)
                                    DispatchQueue.main.async {
                                        fetchDatabaseVM.lessons = lessons
                                        if playerViewModel.isPlaying(urlString: playerViewModel.currentPlayingURL ?? "") {
                                            playerViewModel.pause()
                                        } else {
                                            playerViewModel.playAudio(from: playerViewModel.currentPlayingURL ?? "",
                                                                      playlist: fetchDatabaseVM.lessons,
                                                                      trackIndex: playerViewModel.currentTrackIndex,
                                                                      type: course.type,
                                                                      isFemale: isFemale,
                                                                      course: course)
                                        }
                                    }
                                }
                            } else {
                                if playerViewModel.isAudioPlaying() {
                                    playerViewModel.pause()
                                } else {
                                    //guard let url = URL(string: self.url) else { return }
                                    guard let url = playerViewModel.currentPlayingURL, let path = URL(string: url) else {
                                        print("error")
                                        return
                                    }
                                    playerViewModel.playLocalAudioFrom(url: path, lessonName: playerViewModel.lessonName)
                                }
                            }
                        }, label: {
                            Image(systemName: playerViewModel.isAudioPlaying() ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 85))
                                .foregroundStyle(Color(uiColor: .init(red: 63/255,
                                                                      green: 65/255,
                                                                      blue: 78/255,
                                                                      alpha: 1)))
                        })
                        .overlay {
                            Circle()
                                .stroke(Color(uiColor: .init(red: 160/255,
                                                             green: 163/255,
                                                             blue: 177/255,
                                                             alpha: 1)).opacity(0.7),
                                        lineWidth: 12)
                        }
                        
                        Button(action: {
                            playerViewModel.seek(by: 15) { isPremium in
                                if !isPremium && playerViewModel.currentTrackIndex > 0 {
                                    playerViewModel.player?.pause()
                                    isPressedDownloadWithoutPremium = true
                                }
                            }
                        }, label: {
                            Image(systemName: "goforward.15")
                                .foregroundStyle(course.type == .story || activeDarkModel ? .white : .gray)
                                .font(.system(size: 35))
                        })
                    }
                    .padding()
                    
                    ZStack {
                        if playerViewModel.totalTime > 0 {
                            // Фоновый слой для отображения прогресса буферизации
                            let clampedBufferedTime = max(0, min(playerViewModel.bufferedTime, playerViewModel.totalTime))
                                ProgressView(value: clampedBufferedTime, total: playerViewModel.totalTime)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .gray.opacity(0.6)))
                                    .padding(.horizontal)
                            
                            Slider(value: Binding(get: {
                                self.sliderValue
                            }, set: { newValue in
                                sliderValue = newValue
                                let newTime = CMTime(seconds: newValue * self.playerViewModel.duration.seconds, preferredTimescale: 600)
                                playerViewModel.player?.seek(to: newTime)
                                playerViewModel.currentTime = newTime
                            }), in: 0...1)
                            .padding()
                            .tint(course.type == .story || activeDarkModel ? .white : .black)
                            .onChange(of: playerViewModel.currentTime) { newValue in
                                if playerViewModel.duration.seconds.isFinite && playerViewModel.duration.seconds > 0 {
                                    self.sliderValue = newValue.seconds / playerViewModel.duration.seconds
                                }
                            }
                        } else {
                            LoadingAnimationButton()
                        }
                    }
                    
                    
                    HStack {
                        Text(playerViewModel.formatTime(time: playerViewModel.currentTime))
                            .foregroundStyle(course.type == .story || activeDarkModel ? .white : .black)
                            .font(.system(size: 13, weight: .light, design: .rounded))
                        Spacer()
                        if playerViewModel.duration != .zero {
                            Text(playerViewModel.formatTime(time: playerViewModel.duration))
                                .foregroundStyle(course.type == .story || activeDarkModel ? .white : .black)
                                .font(.system(size: 13, weight: .light, design: .rounded))
                        } else {
                           LoadingAnimationButton()
                        }
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            if /*let _ = currentUser?.uid, !yandexViewModel.yandexUserID.isEmpty,*/ let lesson = lesson {
                isDownloaded = fileManagerService.isDownloaded(lesson: lesson, course: course)
                print("isDownloaded: \(isDownloaded)")
            }
            requestReview()

        }
        .sheet(isPresented: $isPressedDownloadWithoutPremium, content: {
            PremiumScreen()
        })
        .sheet(isPresented: $isPressedDownloadWithoutPremium, content: {
            PremiumScreen()
        })
    }
}

//#Preview {
//    PlayerScreen(lesson: Lesson(audioMaleURL: "https://firebasestorage.googleapis.com/v0/b/relax-8e1d3.appspot.com/o/meditations%2Frelationships%2Ffemale%2Frelationships5Female.mp3?alt=media&token=4d6dbb41-2ffb-4f70-9fbb-adb2fdc4c095", audioFemaleURL: "https://firebasestorage.googleapis.com/v0/b/relax-8e1d3.appspot.com/o/meditations%2Frelationships%2Ffemale%2Frelationships5Female.mp3?alt=media&token=4d6dbb41-2ffb-4f70-9fbb-adb2fdc4c095", name: "Доверие как основа крепких отношений", duration: "8", lessonID: "relationship5", trackIndex: 4), isFemale: true, course: .init(id: "Relationships", name: "Искусство гармоничных отношений", imageURL: "https://firebasestorage.googleapis.com/v0/b/relax-8e1d3.appspot.com/o/meditations%2Frelationships%2F8388073.jpg?alt=media&token=08c24df0-e129-4b36-95fd-3275bc0cb357", color: .init(red: 128/255, green: 129/255, blue: 282/255), duration: "8", description: "", listenedCount: 8, type: .meditation, isDaily: false, likes: 9), url: "")
//        .environmentObject(DownloadManager())
//}


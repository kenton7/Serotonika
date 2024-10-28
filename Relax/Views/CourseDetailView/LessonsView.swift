//
//  LessonsView.swift
//  Relax
//
//  Created by Илья Кузнецов on 05.07.2024.
//

import SwiftUI

//MARK: - LessonsView
struct LessonsView: View {
    
    @Binding var isFemale: Bool
    @EnvironmentObject private var viewModel: CoursesViewModel
    @State private var isPlaying = false
    @State private var playingURL: String? = nil
    let course: CourseAndPlaylistOfDayModel
    @StateObject private var databaseViewModel = ChangeDataInDatabase.shared
    @EnvironmentObject private var premiumViewModel: PremiumViewModel
    @State private var isTappedOnName = false
    @State private var lesson: Lesson?
    @State private var url: String = ""
    //@StateObject private var playerVM = PlayerViewModel.shared
    @EnvironmentObject private var playerVM: PlayerViewModel
    @State private var lessons = [Lesson]()
    @State private var isPressedWithoutPremium = false
    @State private var isErrorWhenPlaying = false
    
    @State private var config: PlayerConfig = .init()
    @StateObject private var config2 = PlayerConfig2.shared
    
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        NavigationStack {
            VStack {
                ForEach(lessons, id: \.name) { file in
                    HStack(spacing: 20) {
                        Button(action: {
                            if premiumViewModel.hasUnlockedPremuim || file.trackIndex! == 0 {
                                let impactMed = UIImpactFeedbackGenerator(style: .soft)
                                impactMed.impactOccurred()
                                isPressedWithoutPremium = false
                                url = isFemale ? file.audioFemaleURL : file.audioMaleURL
                                self.lesson = file
                                //self.config.selectedContentItem = file
                                self.config2.selectedContentItem = file
                                databaseViewModel.updateListeners(course: course, type: course.type)
                                //                                withAnimation(.easeInOut(duration: 0.3)) {
                                //                                    config2.showMiniPlayer = true
                                //                                }
                                if playerVM.isPlaying(urlString: url) {
                                    playerVM.pause()
                                } else {
                                    playerVM.playAudio(from: url,
                                                       playlist: lessons,
                                                       trackIndex: file.trackIndex,
                                                       type: course.type,
                                                       isFemale: isFemale,
                                                       course: course)
                                }
                            } else {
                                guard let trackIndex = file.trackIndex else {
                                    isPressedWithoutPremium = true
                                    return
                                }
                                if trackIndex > 0 {
                                    isPressedWithoutPremium = true
                                }
                            }
                        }, label: {
                            ZStack {
                                Circle()
                                    .frame(width: 50, height: 50)
                                    .foregroundStyle(Color(uiColor: .init(red: CGFloat(course.color.red) / 255,
                                                                          green: CGFloat(course.color.green) / 255,
                                                                          blue: CGFloat(course.color.blue) / 255,
                                                                          alpha: 1)))
                                Image(systemName: playerVM.isPlaying(urlString: isFemale ? file.audioFemaleURL : file.audioMaleURL) ? "pause.fill" : "play.fill")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 15, design: .rounded)).bold()
                            }
                        })
                        .padding(.vertical)
                        
                        Button(action: {
                            if premiumViewModel.hasUnlockedPremuim || file.trackIndex! == 0 {
                                isTappedOnName = true
                                isPressedWithoutPremium = false
                                let impactMed = UIImpactFeedbackGenerator(style: .soft)
                                impactMed.impactOccurred()
                                url = isFemale ? file.audioFemaleURL : file.audioMaleURL
                                if !url.isEmpty {
                                    playerVM.playAudio(from: url,
                                                       playlist: lessons,
                                                       trackIndex: file.trackIndex,
                                                       type: course.type,
                                                       isFemale: isFemale,
                                                       course: course)
                                    databaseViewModel.updateListeners(course: course, type: course.type)
                                    self.lesson = file
                                    self.config2.selectedContentItem = file
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        config2.showMiniPlayer = true
                                    }
                                } else {
                                    isErrorWhenPlaying = true
                                }
                            } else {
                                guard let trackIndex = file.trackIndex else {
                                    isPressedWithoutPremium = true
                                    return
                                }
                                if trackIndex > 0 {
                                    isPressedWithoutPremium = true
                                }
                            }
                        }, label: {
                            HStack {
                                VStack {
                                    HStack {
                                        Text(file.name)
                                            .padding(.vertical, 2)
                                            .foregroundStyle(course.type == .story || activeDarkModel ? .white : .black)
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    HStack {
                                        Text("\(file.duration) мин.")
                                            .foregroundStyle(Color(uiColor: .secondaryTextColor))
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                }
                                Spacer()
                            }
                            .contentShape(.rect)
                            .frame(maxWidth: .infinity)
                        })
                        .fullScreenCover(isPresented: $isTappedOnName, content: {
                            if let lesson = lesson {
                                PlayerScreen(lesson: lesson, isFemale: isFemale, course: course, url: isFemale ? lesson.audioFemaleURL : lesson.audioMaleURL)
                            }
                        })
                        .alert("Ошибка при воспроизведении. Голос для данного материала пока недоступен.",
                               isPresented: $isErrorWhenPlaying) {
                            Button("OK", role: .cancel) {}
                        }
                        Spacer()
                    }
                    Divider()
                }
                
                //                GeometryReader {
                //                    let size = $0.size
                //                    if config.showMiniPlayer {
                //                        MiniPlayerView(size: size, config: $config)
                //                    }
                //                }
            }
        }
        .sheet(isPresented: $isPressedWithoutPremium, content: {
            PremiumScreen()
        })
        .padding()
        .task {
            lessons = await viewModel.fetchCourseDetails(type: course.type, courseID: course.id)
        }
    }
}


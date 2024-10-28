//
//  CourseDetailView.swift
//  Relax
//
//  Created by Илья Кузнецов on 30.06.2024.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct CourseDetailView: View {
    
    var course: CourseAndPlaylistOfDayModel
    var size: CGSize
    var safeArea: EdgeInsets
    @State private var likesCount: Int?
    @State private var isLiked = false
    @StateObject private var headerViewModel = HeaderDetailCourse()
    @EnvironmentObject private var databaseViewModel: ChangeDataInDatabase
    @EnvironmentObject private var coursesViewModel: CoursesViewModel
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @EnvironmentObject private var yandexViewModel: YandexAuthorization
    @EnvironmentObject private var premiumViewModel: PremiumViewModel
    @EnvironmentObject private var downloadManager: DownloadManager
    private let user = Auth.auth().currentUser
    private let fileManagerService: IFileManagerSerivce = FileManagerSerivce()
    @State private var isFemale = true
    @State private var isSelected = false
    @State private var lessons = [Lesson]()
    @State private var isDownloaded = false
    @State private var isPressedDownloadWithoutPremium = false
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if course.type == .story {
                    Color(uiColor: .init(red: 3/255, green: 23/255, blue: 76/255, alpha: 1)).ignoresSafeArea()
                }
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            headerViewModel.createHeaderView(course: course, size: size, safeArea: safeArea)
                                .zIndex(1)
                            createMainContent()
                        }
                        .id("mainScrollView")
                        .background {
                            ScrollDetector { offset in
                                headerViewModel.offsetY = -offset
                            } onDraggingEnd: { offset, velocity in
                                if headerViewModel.needToScroll(offset: offset,
                                                                velocity: velocity,
                                                                safeArea: safeArea,
                                                                size: size) {
                                    withAnimation {
                                        proxy.scrollTo("mainScrollView", anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            databaseViewModel.getLikesIn(course: course, courseType: course.type)
            databaseViewModel.checkIfUserLiked(userID: user?.uid ?? yandexViewModel.yandexUserID, course: course)
            databaseViewModel.getListenersIn(course: course, courseType: course.type)
            databaseViewModel.storyInfo(course: course, isFemale: isFemale)
        }
        .task {
            lessons = await coursesViewModel.fetchCourseDetails(type: course.type, courseID: course.id)
        }
        .sheet(isPresented: $isPressedDownloadWithoutPremium, content: {
            PremiumScreen()
        })
    }
    
    @ViewBuilder
    func createMainContent() -> some View {
        VStack {
            HStack {
                Text(course.name)
                    .padding(.horizontal)
                    .foregroundStyle(course.type == .story || activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                           green: 65/255,
                                                                                           blue: 78/255,
                                                                                           alpha: 1)))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                databaseViewModel.isLiked.toggle()
                                let impactMed = UIImpactFeedbackGenerator(style: .soft)
                                impactMed.impactOccurred()
                            }
                            if databaseViewModel.isLiked {
                                databaseViewModel.userLiked(course: course,
                                                            type: .increment,
                                                            isLiked: true,
                                                            userID: user?.uid ?? yandexViewModel.yandexUserID,
                                                            courseType: course.type)
                            } else {
                                databaseViewModel.userLiked(course: course,
                                                            type: .decrement,
                                                            isLiked: false,
                                                            userID: user?.uid ?? yandexViewModel.yandexUserID,
                                                            courseType: course.type)
                            }
                        }, label: {
                            Image(systemName: databaseViewModel.isLiked ? "heart.fill" : "heart")
                                .bold()
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                                .foregroundColor(course.type == .story || activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                                       green: 65/255,
                                                                                                       blue: 78/255,
                                                                                                       alpha: 1)))
                                .frame(width: 50, height: 50)
                                .background(.clear)
                                .overlay(
                                    Circle()
                                        .stroke(course.type == .story || activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                                      green: 65/255,
                                                                                                      blue: 78/255,
                                                                                                      alpha: 1)),
                                                lineWidth: 2)
                                )
                                .clipShape(.circle)
                        })
                        
                        if !isDownloaded {
                            Button(action: {
                                if premiumViewModel.hasUnlockedPremuim {
                                    isPressedDownloadWithoutPremium = false
                                    Task.detached {
                                        let _ = try await downloadManager.downloadAllCourse(course: course,
                                                                                              courseType: course.type,
                                                                                              isFemale: isFemale,
                                                                                              lessons: lessons)
                                        await MainActor.run {
                                            withAnimation {
                                                self.isDownloaded = true
                                            }
                                        }
                                    }
                                } else {
                                    isPressedDownloadWithoutPremium = true
                                }
                            }, label: {
                                Image(systemName: "arrow.down")
                                    .bold()
                                    .foregroundStyle(course.type == .story || activeDarkModel ? .white : .black)
                                    .font(.system(size: 25, weight: .bold, design: .rounded))
                                    .frame(width: 50, height: 50)
                                    .background(.clear)
                                    .overlay {
                                        Circle()
                                            .stroke(course.type == .story || activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                                          green: 65/255,
                                                                                                          blue: 78/255,
                                                                                                          alpha: 1)),
                                                    lineWidth: 2)
                                    }
                                    .clipShape(.circle)
                            })
                            .padding(10)
                            .overlay {
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray, lineWidth: 4)
                                        .padding(10)
                                    Circle()
                                        .trim(from: 0, to: downloadManager.totalProgress / 100)
                                        .stroke(Color.green, lineWidth: 4)
                                        .padding(10)
                                        .rotationEffect(.degrees(-90))
                                }
                                .opacity(downloadManager.totalProgress >= 100 ? 0 : 1)
                            }
                        }
                    }
                    Spacer()
            }
            
            HStack {
                Text(course.description)
                    .padding()
                    .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 161/255,
                                                                                     green: 164/255,
                                                                                     blue: 178/255,
                                                                                     alpha: 1)))
                    .font(.system(size: 15, weight: .light, design: .rounded))
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            HStack {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(uiColor: .init(red: 255/255,
                                                              green: 132/255,
                                                              blue: 162/255,
                                                              alpha: 1)))
                    
                    Text("\(databaseViewModel.likes) нравится")
                        .font(.system(size: 14, design: .rounded)).bold()
                        .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 161/255,
                                                                                         green: 164/255,
                                                                                         blue: 178/255,
                                                                                         alpha: 1)))
                }
                
                HStack {
                    Spacer()
                    Image(systemName: "headphones")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(uiColor: .init(red: 103/255,
                                                              green: 200/255,
                                                              blue: 193/255,
                                                              alpha: 1)))
                    Text("\(databaseViewModel.listeners) слушали")
                        .font(.system(size: 14, design: .rounded)).bold()
                        .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 161/255,
                                                                                         green: 164/255,
                                                                                         blue: 178/255,
                                                                                         alpha: 1)))
                }
            }
            .padding()
            
            if course.type != .playlist {
                VStack {
                    HStack {
                        Text("Выберите голос")
                            .foregroundStyle(course.type == .story || activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                                   green: 65/255,
                                                                                                   blue: 78/255,
                                                                                                   alpha: 1)))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    ChangeSpeakersButtons(course: course, isFemale: $isFemale)
                }
            }
            LessonsView(isFemale: $isFemale, course: course)
            Spacer()
        }
        .padding()
        .onAppear {
            do {
                isDownloaded = try fileManagerService.isCourseDownloaded(course: course)
            } catch {
                print(error)
            }
        }
    }
}


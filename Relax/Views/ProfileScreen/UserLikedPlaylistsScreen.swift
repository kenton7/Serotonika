//
//  UserLikedPlaylistsScreen.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 30.08.2024.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import Kingfisher

struct UserLikedPlaylistsScreen: View {
    @EnvironmentObject var meditationsViewModel: CoursesViewModel
    @State private var isSelected = false
    @State var selectedCourse: CourseAndPlaylistOfDayModel?
    @State private var isLoading = true
    @State private var isShowing = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    LoadingAnimation()
                } else {
                    if meditationsViewModel.userLikedMaterials.isEmpty {
                        NoLikesAnimation()
                    } else {
                        ScrollView {
                            VStack {
                                LazyVGrid(columns: [GridItem(.flexible()),
                                                    GridItem(.flexible())],
                                          spacing: 20,
                                          content: {
                                    ForEach(meditationsViewModel.userLikedMaterials) { course in
                                        Button(action: {
                                            isSelected = true
                                            selectedCourse = course
                                        }, label: {
                                            VStack {
                                                KFImage(URL(string: course.imageURL))
                                                    .resizable()
                                                    .placeholder {
                                                        LoadingAnimation()
                                                    }
                                                    .scaledToFit()
                                                    .clipShape(.rect(cornerRadius: 16))
                                                    .overlay {
                                                        ZStack {
                                                            VStack {
                                                                Spacer()
                                                                Rectangle()
                                                                    .fill(Color(uiColor: .init(red: CGFloat(course.color.red) / 255,
                                                                                               green: CGFloat(course.color.green) / 255,
                                                                                               blue: CGFloat(course.color.blue) / 255,
                                                                                               alpha: 1)))
                                                                    .frame(maxWidth: .infinity, maxHeight: 40)
                                                                    .clipShape(.rect(bottomLeadingRadius: 16,
                                                                                     bottomTrailingRadius: 16,
                                                                                     style: .continuous))
                                                                    .overlay {
                                                                        Text(course.name)
                                                                            .foregroundStyle(.white)
                                                                            .minimumScaleFactor(0.5)
                                                                            .font(.system(size: 14,
                                                                                          weight: .bold,
                                                                                          design: .rounded))
                                                                            .shadow(color: .gray, radius: 5)
                                                                    }
                                                            }
                                                        }
                                                    }
                                                    .padding()
                                            }
                                        })
                                    }
                                })
                            }
                            .padding(.bottom)
                            
                        }
                    }
                }
            }
        }
        .navigationTitle("Вам понравилось")
        .navigationDestination(isPresented: $isSelected) {
            if let course = selectedCourse {
                ReadyCourseDetailView(course: course)
            }
        }
        .offset(x: isShowing ? 0 : -1000)
        .animation(.bouncy, value: isShowing)
//        .task {
//            await meditationsViewModel.getCoursesUserLiked()
//            await MainActor.run {
//                isLoading = false
//            }
//        }
        .onAppear {
            isShowing = true
            Task {
                await meditationsViewModel.getCoursesUserLiked()
                await MainActor.run {
                    isLoading = false
                }
            }
        }
        .onDisappear {
            isShowing = false
        }
    }
}

struct LikedNightStoriesView: View {
    
    @EnvironmentObject var nightStoriesViewModel: NightStoriesViewModel
    @Binding var isSelected: Bool
    @Binding var isLoading: Bool
    @Binding var isShowing: Bool
    @Binding var selectedStory: CourseAndPlaylistOfDayModel?
    
    var body: some View {
        NavigationStack {
            LazyVGrid(columns: [GridItem(.flexible()),
                                GridItem(.flexible())],
                      spacing: 20,
                      content: {
                ForEach(nightStoriesViewModel.userLikedMaterials) { story in
                    Button(action: {
                        isSelected = true
                        selectedStory = story
                    }, label: {
                        VStack {
                            KFImage(URL(string: story.imageURL))
                                .resizable()
                                .placeholder {
                                    LoadingAnimation()
                                }
                                .scaledToFit()
                                .clipShape(.rect(cornerRadius: 16))
                                .overlay {
                                    ZStack {
                                        VStack {
                                            Spacer()
                                            Rectangle()
                                                .fill(Color(uiColor: .init(red: CGFloat(story.color.red) / 255,
                                                                           green: CGFloat(story.color.green) / 255,
                                                                           blue: CGFloat(story.color.blue) / 255,
                                                                           alpha: 1)))
                                                .frame(maxWidth: .infinity, maxHeight: 40)
                                                .clipShape(.rect(bottomLeadingRadius: 16,
                                                                 bottomTrailingRadius: 16,
                                                                 style: .continuous))
                                                .overlay {
                                                    Text(story.name)
                                                        .foregroundStyle(.white)
                                                        .font(.system(size: 14,
                                                                      weight: .bold,
                                                                      design: .rounded))
                                                        .shadow(color: .gray, radius: 5)
                                                }
                                        }
                                    }
                                }
                                .padding()
                        }
                    })
                }
            })
        }
        .offset(x: isShowing ? 0 : -1000)
        .animation(.bouncy, value: isShowing)
        .task {
            await nightStoriesViewModel.getCoursesUserLiked()
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct LikedMusicView: View {
    
    @StateObject private var musicViewModel = MusicFilesViewModel()
    @Binding var isSelected: Bool
    @Binding var isLoading: Bool
    @Binding var isShowing: Bool
    @Binding var selectedPlaylist: CourseAndPlaylistOfDayModel?
    
    var body: some View {
        NavigationStack {
            LazyVGrid(columns: [GridItem(.flexible()),
                                GridItem(.flexible())],
                      spacing: 20,
                      content: {
                ForEach(musicViewModel.userLikedMaterials) { music in
                    Button(action: {
                        isSelected = true
                        selectedPlaylist = music
                    }, label: {
                        VStack {
                            KFImage(URL(string: music.imageURL))
                                .resizable()
                                .placeholder {
                                    LoadingAnimation()
                                }
                                .scaledToFit()
                                .clipShape(.rect(cornerRadius: 16))
                                .overlay {
                                    ZStack {
                                        VStack {
                                            Spacer()
                                            Rectangle()
                                                .fill(Color(uiColor: .init(red: CGFloat(music.color.red) / 255,
                                                                           green: CGFloat(music.color.green) / 255,
                                                                           blue: CGFloat(music.color.blue) / 255,
                                                                           alpha: 1)))
                                                .frame(maxWidth: .infinity, maxHeight: 40)
                                                .clipShape(.rect(bottomLeadingRadius: 16,
                                                                 bottomTrailingRadius: 16,
                                                                 style: .continuous))
                                                .overlay {
                                                    Text(music.name)
                                                        .foregroundStyle(.white)
                                                        .font(.system(size: 14,
                                                                      weight: .bold,
                                                                      design: .rounded))
                                                        .shadow(color: .gray, radius: 5)
                                                }
                                        }
                                    }
                                }
                                .padding()
                        }
                    })
                }
            })
        }
        .offset(x: isShowing ? 0 : -1000)
        .animation(.bouncy, value: isShowing)
        .task {
            await musicViewModel.getCoursesUserLiked()
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

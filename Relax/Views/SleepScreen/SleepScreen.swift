//
//  SleepScreen.swift
//  Relax
//
//  Created by Илья Кузнецов on 09.07.2024.
//

import SwiftUI
import Kingfisher

struct SleepScreen: View {
    @EnvironmentObject var nightStoriesVM: NightStoriesViewModel
    
    @State private var isShowing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .init(red: 3/255,
                                     green: 23/255,
                                     blue: 76/255,
                                     alpha: 1))
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        HeaderView(isShowing: $isShowing)
                        //StoryGenresView(type: .story)
                        AllStoriesView(isShowing: $isShowing)
                    }
                }
                .ignoresSafeArea()
            }
            .onAppear {
                isShowing = true
            }
            .onDisappear {
                isShowing = false
            }
        }
        .refreshable {
            nightStoriesVM.fetchNightStories()
        }
    }
}


//MARK: - HeaderView
struct HeaderView: View {
    
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .fill(Color(uiColor: .init(red: 30/255,
                                               green: 38/255,
                                               blue: 94/255,
                                               alpha: 1)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(y: -100)
                Image("SleepScreenHeaderBackground")
                    .scaleEffect(CGSize(width: 1.2, height: 1.0))
                Image("OnSleepScreenHeaderLayer")
                VStack {
                    Text("Истории на ночь")
                        .padding()
                        .foregroundStyle(.white)
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    Text("Успокаивающие сказки на ночь помогут вам погрузиться в глубокий и естественный сон")
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                        .font(.system(size: 20, weight: .light, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                .offset(y: isShowing ? 0 : -1000)
                .animation(.bouncy, value: isShowing)
            }
        }
        .ignoresSafeArea()
    }
}

//MARK: - StoryGenresView
//struct StoryGenresView: View {
//    
//    @State private var isSelected = false
//    @StateObject private var selectGenreVM = SelectGenreViewModel()
//    @EnvironmentObject var nightStoriesVM: NightStoriesViewModel
//    @EnvironmentObject var meditationVM: CoursesViewModel
//    let type: Types
//    @State private var isShowing = false
//    
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            LazyHGrid(rows: [GridItem(.flexible())], content: {
//                HStack {
//                    ForEach(selectGenreVM.genres.indices, id: \.self) { index in
//                        Button(action: {
//                            withAnimation(.easeInOut(duration: 0.6)) {
//                                selectGenreVM.selectGenre(at: index)
//                                nightStoriesVM.filterResults(by: selectGenreVM.selectedGenre)
//                                if type == .story {
//                                    Task.detached {
//                                        await nightStoriesVM.filterResults(by: selectGenreVM.selectedGenre)
//                                    }
//                                } else {
//                                    Task.detached {
//                                        await meditationVM.filterResults(by: selectGenreVM.selectedGenre)
//                                    }
//                                }
//                            }
//                        }, label: {
//                            VStack {
//                                ZStack {
//                                    Circle()
//                                        .frame(width: 70, height: 70)
//                                        .foregroundStyle(selectGenreVM.genres[index].isSelected ? Color(uiColor: .init(red: 142/255,
//                                                                                                                       green: 151/255,
//                                                                                                                       blue: 253/255
//                                                                                                                       , alpha: 1)) : Color(uiColor: .init(red: 88/255, green: 104/255,
//                                                                                                                                                           blue: 148/255,
//                                                                                                                                                           alpha: 1)))
//                                    Image(systemName: selectGenreVM.genres[index].image)
//                                        .foregroundStyle(.white)
//                                        .font(.system(size: 25))
//                                }
//                                Text(selectGenreVM.genres[index].genre)
//                                
//                                    .foregroundStyle(
//                                        (type == .story && selectGenreVM.genres[index].isSelected) ? .white : (type == .meditation && selectGenreVM.genres[index].isSelected ? .black : .gray)
//                                    )
//                                    .bold()
//                            }
//                        })
//                        .padding(.horizontal)
//                    }
//                }
//                .padding()
//            })
//            .padding(.horizontal)
//            .frame(height: 100)
//            .offset(x: isShowing ? 0 : 1000)
//            .animation(.easeInOut, value: isShowing)
//        }
//        .padding(.top, -30)
//        .padding(.bottom)
//        .onAppear {
//            withAnimation {
//                selectGenreVM.selectGenre(at: 0)
//            }
//            isShowing = true
//        }
//        .onDisappear {
//            isShowing = false
//        }
//    }
//}


//MARK: - AllStoriesView
struct AllStoriesView: View {
    
    @EnvironmentObject var nightStoriesVM: NightStoriesViewModel
    @State private var isSelected = false
    @State var selectedStory: CourseAndPlaylistOfDayModel?
    @Binding var isShowing: Bool
    
    var body: some View {
        NavigationStack {
            LazyVGrid(columns: [GridItem(.flexible()),
                                GridItem(.flexible())
                               ], spacing: 20) {
                ForEach(nightStoriesVM.filteredStories) { story in
                    Button(action: {
                        isSelected = true
                        selectedStory = story
                    }, label: {
                        VStack {
                            KFImage(URL(string: story.imageURL))
                                .resizable()
                                .placeholder {
                                    LoadingAnimationButton()
                                }
                                .scaledToFit()
                                .clipShape(.rect(cornerRadius: 16))
                                .padding(.horizontal)

                            VStack {
                                HStack {
                                    Text(story.name)
                                        .padding()
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.leading)
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("\(story.duration) мин • \(story.type.rawValue)")
                                        //.padding(.horizontal, 10)
                                        .padding(.horizontal)
                                        .foregroundStyle(Color(uiColor: .init(red: 152/255,
                                                                              green: 161/255,
                                                                              blue: 189/255,
                                                                              alpha: 1)))
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                            }
                        }
                    })
                }
            }
                               .padding(.horizontal)
                               .padding(.bottom, 110)
                               .offset(x: isShowing ? 0 : -1000)
                               .animation(.bouncy, value: isShowing)
                               .onAppear {
                                   //nightStoriesVM.filterResults(by: "Всё")
                               }
        }
        .navigationDestination(isPresented: $isSelected) {
            if let selectedStory {
                ReadyCourseDetailView(course: selectedStory)
            }
        }
    }
}


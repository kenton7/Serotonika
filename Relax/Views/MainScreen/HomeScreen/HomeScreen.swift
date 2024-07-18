//
//  HomeScreen.swift
//  Relax
//
//  Created by Илья Кузнецов on 26.06.2024.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import FirebaseCore
import CoreData
import AVKit

struct HomeScreen: View {
    
    @StateObject private var viewModel = CoursesViewModel()
    @StateObject private var recommendationsViewModel = RecommendationsViewModel()
    @StateObject private var nightStoriesViewModel = NightStoriesViewModel()
    
    var body: some View {
        
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    Text("Сияние души")
                        .padding()
                        .foregroundStyle(Color(uiColor: .init(red: 63/255,
                                                              green: 65/255,
                                                              blue: 78/255,
                                                              alpha: 1)))
                        .font(.system(.title2, design: .rounded)).bold()
                    
                    GreetingView()
                    DailyRecommendations()
                    DailyThoughts()
                    RecommendationsScreen()
                    NightStories()
                    Spacer()
                }
            }
        }
        .tint(.white)
        .refreshable {
            Task.detached {
                await viewModel.getCourses(isDaily: true)
                await viewModel.getCourses(isDaily: false)
            }
            recommendationsViewModel.fetchRecommendations()
            nightStoriesViewModel.fetchNightStories()
        }
    }
    
    
}

//MARK: - GreetingView
struct GreetingView: View {
    
    @StateObject private var homeScreenViewModel = HomeScreenViewModel()
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(homeScreenViewModel.greeting + "!")
                        .padding()
                        .foregroundStyle(Color(uiColor: .init(red: 63/255,
                                                              green: 65/255,
                                                              blue: 78/255,
                                                              alpha: 1)))
                        .font(.system(.title, design: .rounded)).bold()
                        .padding(.vertical, -15)
                    Text(homeScreenViewModel.secondaryGreeting)
                        .padding(.horizontal)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color(uiColor: .init(red: 161/255,
                                                              green: 164/255,
                                                              blue: 178/255,
                                                              alpha: 1)))
                }
                Spacer()
            }
            .padding(.vertical)
        }
    }
}

//MARK: - DailyRecommendations
struct DailyRecommendations: View {
    
    @StateObject private var playlistAndCourseOfDay = CoursesViewModel()
    @State private var isCourseTapped: Bool = false
    @State private var isPlaylistTapped = false
    @State private var isStoryTapped = false
    @State private var selectedCourse: CourseAndPlaylistOfDayModel?
    
    private var currentDate: String = {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "dd.MM"
        return df.string(from: date)
    }()

    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Практика дня")
                            .foregroundStyle(.black)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.leading)
                        
                        Text("Обновляется ежедневно")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color(uiColor: .init(red: 161/255,
                                                                  green: 164/255,
                                                                  blue: 178/255,
                                                                  alpha: 1)))
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                HStack(spacing: 15) {
                    ForEach(playlistAndCourseOfDay.dailyCourses, id: \.id) { course in
                        Button(action: {
                            isCourseTapped = true
                            selectedCourse = course
                        }, label: {
                            ZStack {
                                Color(uiColor: .init(red: CGFloat(course.color.red) / 255,
                                                     green: CGFloat(course.color.green) / 255,
                                                     blue: CGFloat(course.color.blue) / 255,
                                                     alpha: 1))
                                .overlay {
                                    VStack {
                                        HStack {
                                            ZStack {
                                                Capsule()
                                                    .fill(Color.red)
                                                    .padding(.horizontal)
                                                    .frame(maxWidth: 100, maxHeight: 40)
                                                    .shadow(radius: 5)
                                                Text(currentDate).bold()
                                                    .padding()
                                            }
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }
                                VStack {
                                    HStack {
                                        Spacer()
                                        AsyncImage(url: URL(string: course.imageURL)) { image in
                                            image.resizable()
                                                .scaledToFit()
                                                //.frame(maxWidth: 400, maxHeight: 300)
                                                .frame(width: 200, height: 150)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    }
                                    Spacer()
                                    HStack {
                                        Text(course.name)
                                            .padding(.horizontal)
                                            .foregroundStyle(.white)
                                            .font(.system(.title3, design: .rounded)).bold()
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    HStack {
                                        Spacer()
                                        Text(course.duration + " " + "мин.")
                                            .padding(.horizontal)
                                            .foregroundStyle(.white)
                                            .font(.system(size: 15, design: .rounded))
                                        Capsule()
                                            .fill(Color.white)
                                            .frame(width: 80, height: 40)
                                            .padding(10)
                                            .overlay {
                                                Text("Начать")
                                                    .foregroundStyle(.black)
                                                    .font(.system(size: 18, design: .rounded))
                                            }
                                    }
                                }
                            }
                        })
                        .clipShape(.rect(cornerRadius: 20))
                        .padding(.horizontal, 0)
                        //.frame(width: 180, height: 230)
                        .frame(maxWidth: .infinity, maxHeight: 230)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 230)
                //.frame(width: 180, height: 230)
                .padding()
            }
        }
        .navigationDestination(isPresented: $isCourseTapped) {
            if let selectedCourse = selectedCourse {
                ReadyCourseDetailView(course: selectedCourse)
            }
        }
        .task {
            await playlistAndCourseOfDay.getCourses(isDaily: true)
        }
    }
}

//MARK: - DailyThoughts
struct DailyThoughts: View {
    
    @State private var isDailyThoughtsTapped = false
    @State private var selectedCourse: CourseAndPlaylistOfDayModel?
    @StateObject private var viewModel = CoursesViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                Button(action: {
                    //selectedCourse = viewModel.dailyThoughts.first
                    selectedCourse = viewModel.allCourses.filter { $0.name == "Ежедневные мысли" }.first
                    print(selectedCourse?.name)
                    isDailyThoughtsTapped = true
                }, label: {
                    ZStack {
                        Color(uiColor: .init(red: 51/255,
                                             green: 50/255,
                                             blue: 66/255,
                                             alpha: 1))
                        Image("DailyThoughtsBackground")
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Ежедневные мысли")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 20, design: .rounded)).bold()
                                Text("МЕДИТАЦИЯ • 10-30 мин")
                                    .lineLimit(1)
                                    .foregroundStyle(.white).bold()
                                    .font(.system(.caption, design: .rounded))
                            }
                            .padding()
                            Spacer()
                            
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 35))
                                .padding()
                        }
                    }
                })
                .clipShape(.rect(cornerRadius: 20))
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationDestination(isPresented: $isDailyThoughtsTapped) {
            if let selectedCourse = selectedCourse {
                ReadyCourseDetailView(course: selectedCourse)
            }
        }
        .task {
            await viewModel.getCourses(isDaily: false)
        }
//        .onAppear {
//            Task.detached {
//                await viewModel.getCourses(isDaily: false)
//            }
//            //viewModel.getCourses(isDaily: false)
//        }
    }
}

//MARK: - RecommendationsScreen
struct RecommendationsScreen: View {
    
    @StateObject private var recommendationsViewModel = RecommendationsViewModel()
    @FetchRequest(
        entity: Topic.entity(),
        sortDescriptors: []
    ) var selectedTopics: FetchedResults<Topic>
    
    //let user = Auth.auth().currentUser
    @State private var isSelected = false
    @State private var selectedCourse: CourseAndPlaylistOfDayModel?
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Рекомендовано для Вас")
                        .padding()
                        .foregroundStyle(Color(uiColor: .init(red: 63/255,
                                                              green: 65/255,
                                                              blue: 78/255,
                                                              alpha: 1)))
                        .font(.system(.title2, design: .rounded)).bold()
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.fixed(150))], spacing: 0, content: {
                        
                        ForEach(recommendationsViewModel.recommendations, id: \.name) { course in
                            Button(action: {
                                selectedCourse = course
                                isSelected = true
                            }, label: {
                                VStack(alignment: .leading) {
                                    ZStack {
                                        Color(uiColor: .init(red: CGFloat(course.color.red) / 255,
                                                             green: CGFloat(course.color.green) / 255,
                                                             blue: CGFloat(course.color.blue) / 255,
                                                             alpha: 1))
                                        
                                        AsyncImage(url: URL(string: course.imageURL)) { image in
                                            image.resizable()
                                                .scaledToFit()
                                                .frame(width: 200, height: 150)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    }
                                    .clipShape(.rect(cornerRadius: 10))
                                    Spacer()
                                    
                                    Text(course.name)
                                        .foregroundStyle(Color(uiColor: .init(red: 63/255,
                                                                              green: 65/255,
                                                                              blue: 78/255,
                                                                              alpha: 1)))
                                        .font(.system(.callout, design: .rounded)).bold()
                                    
                                    Text(course.type.rawValue)
                                        .foregroundStyle(Color(uiColor: .init(red: 161/255,
                                                                              green: 164/255,
                                                                              blue: 178/255,
                                                                              alpha: 1)))
                                        .font(.system(.caption, design: .rounded))
                                }
                            })
                            .padding(.horizontal)
                        }
                    })
                }
            }
        }
        .navigationDestination(isPresented: $isSelected, destination: {
            if let selectedCourse = selectedCourse {
                ReadyCourseDetailView(course: selectedCourse)
            }
        })
    }
}

//MARK: - NightStories
struct NightStories: View {
    
    @StateObject private var nightStoriesViewModel = NightStoriesViewModel()
    @State private var isSelected = false
    @State private var selectedStory: CourseAndPlaylistOfDayModel?
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Истории на ночь")
                        .padding()
                        .foregroundStyle(Color(uiColor: .init(red: 63/255,
                                                              green: 65/255,
                                                              blue: 78/255,
                                                              alpha: 1)))
                        .font(.system(.title2, design: .rounded)).bold()
                    Spacer()
                }
                
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.fixed(150))], spacing: 0, content: {
                            ForEach(nightStoriesViewModel.nightStories, id: \.name) { nightStory in
                                Button(action: {
                                    isSelected = true
                                    selectedStory = nightStory
                                    //nightStoriesViewModel.playStoryFrom(url: nightStory.audioFemaleURL)
                                }, label: {
                                    VStack(alignment: .leading) {
                                        ZStack {
                                            Color(uiColor: .init(red: CGFloat(nightStory.color.red) / 255,
                                                                 green: CGFloat(nightStory.color.green) / 255,
                                                                 blue: CGFloat(nightStory.color.blue) / 255,
                                                                 alpha: 1))
                                            AsyncImage(url: URL(string: nightStory.imageURL)!, scale: 3.4) { image in
                                                image.resizable()
                                                image.scaledToFill()
                                            } placeholder: {
                                                ProgressView()
                                            }
                                            .padding()
                                            .frame(width: 200, height: 150)
                                        }
                                        .clipShape(.rect(cornerRadius: 10))
                                        Spacer()
                                        Text(nightStory.name)
                                            .foregroundStyle(Color(uiColor: .init(red: 63/255,
                                                                                  green: 65/255,
                                                                                  blue: 78/255,
                                                                                  alpha: 1)))
                                            .font(.system(.callout, design: .rounded)).bold()
                                    }
                                })
                                .padding(.horizontal)
                            }
                            NavigationLink {
                                SleepScreen()
                            } label: {
                                ZStack {
                                    Circle()
                                        .frame(width: 70, height: 70)
                                        .foregroundStyle(Color.indigo)
                                    Text("См. \nвсё")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 15, design: .rounded)).bold()
                                }
                            }
                            .padding(.horizontal)
                        })
                    }
                }
                Spacer()
            }
        }
        .padding(.bottom)
        .navigationDestination(isPresented: $isSelected) {
            if let selectedStory = selectedStory {
                ReadyCourseDetailView(course: selectedStory)
            }
        }
    }
}

#Preview {
    HomeScreen()
}

#Preview("RecommendationsScreen") {
    RecommendationsScreen()
}

#Preview("Night Stories") {
    NightStories()
}

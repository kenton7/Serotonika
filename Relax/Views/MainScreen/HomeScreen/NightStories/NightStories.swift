//
//  NightStories.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 21.10.2024.
//

import SwiftUI
import Kingfisher

struct NightStoriesScreen: View {
    
    @StateObject private var nightStoriesViewModel = NightStoriesViewModel()
    @State private var isShowing = true
    
    var body: some View {
        UniversalGridScreen<CourseAndPlaylistOfDayModel>(
            title: "Истории на ночь",
            items: nightStoriesViewModel.nightStories,
            isNightStories: true,
            colorProvider: { item in
                UIColor(red: CGFloat(item.color.red) / 255,
                        green: CGFloat(item.color.green) / 255,
                        blue: CGFloat(item.color.blue) / 255,
                        alpha: 1)
            },
            imageProvider: { item in
                item.imageURL
            },
            nameProvider: { item in
                item.name
            },
            destinationViewProvider: { selectedCourse in
                AnyView(ReadyCourseDetailView(course: selectedCourse))
            },
            isShowing: $isShowing
        )
    }
}

//MARK: - NightStories
struct NightStories: View {
    
    @StateObject private var nightStoriesViewModel = NightStoriesViewModel()
    @State private var isSelected = false
    @State private var selectedStory: CourseAndPlaylistOfDayModel?
    @Binding var isShowing: Bool
    @Environment(\.currentTab) private var selectedTab
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                //Spacer()
                HStack {
                    Text("Истории на ночь")
                        .padding(.top)
                        .padding(.horizontal)
                        .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                         green: 65/255,
                                                                                         blue: 78/255,
                                                                                         alpha: 1)))
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    Spacer()
                }
                
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.flexible(minimum: 230))], spacing: 0, content: {
                            ForEach(nightStoriesViewModel.nightStories, id: \.name) { nightStory in
                                Button(action: {
                                    isSelected = true
                                    selectedStory = nightStory
                                }, label: {
                                    VStack(alignment: .leading, spacing: 0) {
                                                KFImage(URL(string: nightStory.imageURL)!)
                                                    .resizable()
                                                    .placeholder {
                                                        LoadingAnimationButton()
                                                    }
                                                    .scaledToFill()
                                                    .frame(width: 200, height: 150)
                                                    .scaleEffect(CGSize(width: 1.5, height: 1.1))
                                                    .clipShape(.rect(cornerRadius: 10))

                                        Text(nightStory.name)
                                            .padding(.top)
                                                .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                                                 green: 65/255,
                                                                                                                 blue: 78/255,
                                                                                                                 alpha: 1)))
                                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                                .frame(maxWidth: 200, alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true) // перенос текст при необходимости
                                    }
                                })
                               .padding(.horizontal)
                            }
                            Button {
                                selectedTab.wrappedValue = .sleep
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
                //Spacer()
            }
            .offset(x: isShowing ? 0 : -300)
            .animation(.bouncy, value: isShowing)
        }
        .padding(.bottom, 30)
        .navigationDestination(isPresented: $isSelected) {
            if let selectedStory = selectedStory {
                ReadyCourseDetailView(course: selectedStory)
            }
        }
    }
}

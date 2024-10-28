//
//  HomeScreen.swift
//  Relax
//
//  Created by Илья Кузнецов on 26.06.2024.
//

import SwiftUI
import Kingfisher

struct HomeScreen: View {
    
    @StateObject private var viewModel = CoursesViewModel()
    @StateObject private var nightStoriesViewModel = NightStoriesViewModel()
    @EnvironmentObject var yandexViewModel: YandexAuthorization
    @StateObject private var recommendationsViewModel = RecommendationsViewModel(yandexViewModel: .shared)
    @State private var isShowing = false
    @State private var isScrolling = false
    @EnvironmentObject var navigationService: NavigationService
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    GreetingView(isShowing: $isShowing)
                        .padding(.top)
                    NewMaterialsScreen()
                    DailyRecommedationsScreen()
                    DailyThoughts(isShowing: $isShowing)
                    RecommendationScreen()
                    NightStoriesScreen()
                }
                .padding(.vertical)
                .modifier(ScrollTrackingModifier(isScrolling: $isScrolling))
            }
            .modifier(HeaderModifier(isScrolling: $isScrolling, title: "Серотоника", activeDarkModel: $activeDarkModel, isShowing: $isShowing))
        }
        .tint(.white)
        .refreshable {
            async let _ = viewModel.getCoursesNew(isDaily: true, path: .allCourses)
            async let _ = viewModel.getCoursesNew(isDaily: false, path: .allCourses)
            async let _ = viewModel.getNewMaterials()
            async let _ = recommendationsViewModel.fetchRecommendations()
            async let _ = nightStoriesViewModel.fetchNightStories()
        }
        .onAppear {
            isShowing = true
        }
        .onDisappear {
            isShowing = false
        }
    }
}

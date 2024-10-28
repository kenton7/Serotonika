//
//  RecommendationsScreen.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 21.10.2024.
//

import SwiftUI
import Kingfisher

struct RecommendationScreen: View {
    
    @StateObject private var recommendationsViewModel = RecommendationsViewModel(yandexViewModel: .shared)
    @State private var isShowing = true
    
    var body: some View {
        UniversalGridScreen<CourseAndPlaylistOfDayModel>(
            title: "Рекомендовано для Вас",
            items: recommendationsViewModel.recommendations,
            isNightStories: false,
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

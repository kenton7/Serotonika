//
//  NewMaterialsScreen.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 21.10.2024.
//

import SwiftUI
import Kingfisher

struct NewMaterialsScreen: View {
    @EnvironmentObject var viewModel: CoursesViewModel
    @State private var isShowing = true
    
    var body: some View {        
        UniversalnNewMaterialsAndDailyRec<CourseAndPlaylistOfDayModel>(
            title: "Новое",
            subtitle: "Встречайте обновления для вашего роста!",
            items: viewModel.newMaterials,
            colorProvider: { item in
                UIColor(red: CGFloat(item.color.red) / 255,
                        green: CGFloat(item.color.green) / 255,
                        blue: CGFloat(item.color.blue) / 255,
                        alpha: 1)
            }, imageProvider: { item in
                item.imageURL
            }, nameProvider: { item in
                item.name
            },
            durationProvider: {
                $0.duration
            },
            destinationViewProvider: { selectedCourse in
                AnyView(ReadyCourseDetailView(course: selectedCourse))
            },
            isNewMaterial: true,
            isShowing: $isShowing
        )
        .task {
            await viewModel.getNewMaterials()
        }
    }
}

//
//  MeditationScreen.swift
//  Relax
//
//  Created by Илья Кузнецов on 11.07.2024.
//

import SwiftUI
import Kingfisher

struct MeditationScreen: View {
    @StateObject private var emergencyVM = EmergencyMeditationsViewModel()
    @EnvironmentObject private var meditationsVM: CoursesViewModel
    @State private var isShowing = false
    @State private var isScrolling = false
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    MeditationHeaderView(isShowing: $isShowing)
                        .padding(.top)
                    EmergencyHelp(isShowing: $isShowing)
                        .environmentObject(emergencyVM)
                    AllMeditationsView(isShowing: $isShowing)
                }
                .modifier(ScrollTrackingModifier(isScrolling: $isScrolling))
            }
            .modifier(HeaderModifier(isScrolling: $isScrolling, title: "Медитации", activeDarkModel: $activeDarkModel, isShowing: $isShowing))
        }
        .padding(.bottom)
        .refreshable {
            Task {
                await meditationsVM.getCoursesNew(isDaily: false, path: .allCourses)
                await meditationsVM.getCoursesNew(isDaily: false, path: .emergencyMeditations)
            }
        }
        .onAppear {
            isShowing = true
        }
        .onDisappear {
            isShowing = false
        }
    }
}



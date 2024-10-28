//
//  EmergencyView.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 21.10.2024.
//

import SwiftUI
import Kingfisher

//MARK: - EmergencyHelp
struct EmergencyHelp: View {
    
    @EnvironmentObject private var emergencyViewModel: EmergencyMeditationsViewModel
    @EnvironmentObject private var coursesViewModel: CoursesViewModel
    @State private var isSelected = false
    @State var selectedCourse: CourseAndPlaylistOfDayModel?
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    @Binding var isShowing: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Если помощь нужна здесь и сейчас")
                    .padding()
                    .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 160/255,
                                                                                     green: 163/255,
                                                                                     blue: 177/255,
                                                                                     alpha: 1)))
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .multilineTextAlignment(.center)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20, content: {
                    ForEach(coursesViewModel.emergencyMeditations) { emergencyLesson in
                        Button(action: {
                            isSelected = true
                            selectedCourse = emergencyLesson
                        }, label: {
                            VStack {
                                KFImage(URL(string: emergencyLesson.imageURL))
                                    .resizable()
                                    .placeholder {
                                        LoadingAnimationButton()
                                    }
                                    .scaledToFit()
                                    .clipShape(.rect(cornerRadius: 16))
                                    .padding(.horizontal)
                                Text(emergencyLesson.name)
                                    .foregroundStyle(activeDarkModel ? .white : .black)
                                    .font(.system(size: 15, design: .rounded)).bold()
                            }
                        })
                    }
                })
            }
            .offset(x: isShowing ? 0 : -1000)
            .animation(.bouncy, value: isShowing)
        }
        .navigationDestination(isPresented: $isSelected) {
            if let course = selectedCourse {
                ReadyCourseDetailView(course: course)
            }
        }
        .task {
            await coursesViewModel.getCoursesNew(isDaily: false, path: .emergencyMeditations)
        }
    }
}

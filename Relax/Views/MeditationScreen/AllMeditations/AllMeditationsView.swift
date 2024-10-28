//
//  AllMeditationsView.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 21.10.2024.
//

import SwiftUI
import Kingfisher

//MARK: -  AllMeditationsView
struct AllMeditationsView: View {
    
    @EnvironmentObject var meditationsViewModel: CoursesViewModel
    @State private var isSelected = false
    @State var selectedCourse: CourseAndPlaylistOfDayModel?
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    @Binding var isShowing: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Все медитации")
                    .padding()
                    .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 160/255,
                                                                                     green: 163/255,
                                                                                     blue: 177/255,
                                                                                     alpha: 1)))
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .multilineTextAlignment(.center)
                
                
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()),
                                        GridItem(.flexible())
                                       ], spacing: 20,
                              content: {
                        ForEach(meditationsViewModel.allCourses) { course in
                            Button(action: {
                                isSelected = true
                                selectedCourse = course
                            }, label: {
                                VStack {
                                    KFImage(URL(string: course.imageURL))
                                        .resizable()
                                        .placeholder {
                                            LoadingAnimationButton()
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
                                                                .foregroundStyle(activeDarkModel ? .white : .black)
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
            }
        }
        .navigationDestination(isPresented: $isSelected) {
            if let course = selectedCourse {
                ReadyCourseDetailView(course: course)
            }
        }
        .offset(x: isShowing ? 0 : -1000)
        .animation(.bouncy, value: isShowing)
        .task {
            await meditationsViewModel.getCoursesNew(isDaily: false, path: .allCourses)
        }
    }
}

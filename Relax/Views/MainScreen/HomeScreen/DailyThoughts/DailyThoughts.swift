//
//  DailyThoughts.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 21.10.2024.
//

import SwiftUI

//MARK: - DailyThoughts
struct DailyThoughts: View {
    
    @State private var isDailyThoughtsTapped = false
    @State private var selectedCourse: CourseAndPlaylistOfDayModel?
    @StateObject private var viewModel = CoursesViewModel()
    @Binding var isShowing: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Button(action: {
                    selectedCourse = viewModel.allCourses.filter { $0.name == "Ежедневные мысли" }.first
                    isDailyThoughtsTapped = true
                }, label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .init(red: 51/255,
                                                       green: 50/255,
                                                       blue: 66/255,
                                                       alpha: 1)))
                            .padding(.horizontal)
                        
                        Image("DailyThoughtsBackground")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal)
                        
                        VStack {
                            HStack {
                                Text("Ежедневные мысли")
                                    .padding(.horizontal)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 20, design: .rounded)).bold()
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("МЕДИТАЦИЯ • 10-30 мин")
                                    .padding(.horizontal)
                                    .lineLimit(1)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 14, weight: .light, design: .rounded))
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        HStack {
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 35))
                                            .padding()
                        }
                        .padding(.trailing)
                    }
                })
                .clipShape(.rect(cornerRadius: 20))
                .frame(maxWidth: .infinity)
                .offset(x: isShowing ? 0 : -700)
                .animation(.bouncy, value: isShowing)
            }
        }
        .navigationDestination(isPresented: $isDailyThoughtsTapped) {
            if let selectedCourse = selectedCourse {
                ReadyCourseDetailView(course: selectedCourse)
            }
        }
        .task {
            await viewModel.getCoursesNew(isDaily: false, path: .allCourses)
        }
    }
}

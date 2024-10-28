//
//  UserInterestsTopicScreen.swift
//  Relax
//
//  Created by Илья Кузнецов on 25.06.2024.
//

import SwiftUI
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import Kingfisher

struct UserInterestsTopicScreen: View {
    
    @State private var selectedTopics: [CourseAndPlaylistOfDayModel] = []
    @State private var isContinueTapped = false
    private let topicDataService = CoreDataService.shared
    @StateObject private var coursesVM = CoursesViewModel()
    @EnvironmentObject var yandexViewModel: YandexAuthorization
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    private let firebaseUser = Auth.auth().currentUser
    
    var body: some View {
        
        let columns = [GridItem(.flexible(minimum: 180, maximum: 250)),
                       GridItem(.flexible(minimum: 180, maximum: 250))]
        
        NavigationStack {
            ZStack {
                    Image("TopicsBackground").ignoresSafeArea()
                ScrollView {
                    VStack {
                        HStack {
                            Text("Что вам по душе?")
                                .padding(.top)
                                .padding(.horizontal)
                                .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255, green: 65/255, blue: 78/255, alpha: 1)))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding()
                        
                        HStack {
                            Text("Выберите темы, \nна которых вы хотели бы сфокусироваться:")
                                .padding(.horizontal)
                                .font(.system(size: 17, weight: .light, design: .rounded))
                                .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 161/255, green: 164/255, blue: 178/255, alpha: 1)))
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        ScrollView {
                            LazyVGrid(columns: columns, alignment: .center, spacing: 10, content: {
                                ForEach($coursesVM.allCourses, id: \.id) { $topic in
                                    TopicButton(topic: $topic, selectedTopics: $selectedTopics)
                                }
                            })
                            .padding()
                        }
                        
                        Button(action: {
                            isContinueTapped = true
                        }, label: {
                            HStack {
                                Text("Продолжить")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                            }
                            .contentShape(.rect)
                        })
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .defaultButtonColor))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding()
                        .disabled(selectedTopics.isEmpty)
                        .padding(.bottom)
                        .padding(.horizontal)
                    }
                    .padding()
                    .padding(.top)
                    .padding(.bottom)
                }
            }
        }
        .navigationDestination(isPresented: $isContinueTapped, destination: {
            RemindersScreen(isFromSettings: false)
        })
        .task {
            await coursesVM.getCoursesNew(isDaily: false, path: .allCourses)
        }
        .navigationBarBackButtonHidden()
    }
}

struct TopicButton: View {
    @Binding var topic: CourseAndPlaylistOfDayModel
    @Binding var selectedTopics: [CourseAndPlaylistOfDayModel]
    private let topicDataService = CoreDataService.shared
    @EnvironmentObject var yandexViewModel: YandexAuthorization
    
    var body: some View {
                
        Button(action: {
            if let userID = Auth.auth().currentUser?.uid ?? yandexViewModel.userInfo?.id {
                withAnimation {
                    if !selectedTopics.contains(where: { $0.name == topic.name }) {
                        selectedTopics.append(topic)
                        topic.isSelected = true
                        let topicDict = ["name": topic.name]
                        Database.database(url: .databaseURL).reference().child("users").child(userID).child("selectedTopics").child(topic.name).setValue(topicDict)
                    } else {
                        selectedTopics.removeAll(where: { $0.name == topic.name })
                        topic.isSelected = false
                        Database.database(url: .databaseURL).reference().child("users").child(userID).child("selectedTopics").child(topic.name).removeValue()
                    }
                }
            }
        }, label: {
            ZStack {
                Color(uiColor: .init(red: CGFloat(topic.color.red) / 255,
                                     green: CGFloat(topic.color.green) / 255,
                                     blue: CGFloat(topic.color.blue) / 255,
                                     alpha: 1))
                VStack {
                    
                    KFImage(URL(string: topic.imageURL))
                        .resizable()
                        .placeholder {
                            LoadingAnimation()
                                .frame(width: 40, height: 40)
                        }
                        .scaledToFit()
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay {
                            ZStack {
                                VStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(Color(uiColor: .init(red: CGFloat(topic.color.red) / 255,
                                                                   green: CGFloat(topic.color.green) / 255,
                                                                   blue: CGFloat(topic.color.blue) / 255,
                                                                   alpha: 1)))
                                        .frame(maxWidth: .infinity, maxHeight: 40)
                                        .clipShape(.rect(bottomLeadingRadius: 16,
                                                         bottomTrailingRadius: 16,
                                                         style: .continuous))
                                }
                            }
                        }
                    .padding()
                }
                VStack {
                    Spacer()
                    HStack {
                        Text(topic.name)
                            .padding()
                            .font(.system(size: 17, design: .rounded))
                            .foregroundStyle(.white).bold()
                            .minimumScaleFactor(0.5)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(topic.isSelected == true ? Color.green : Color.clear, lineWidth: 3)
            )
        })
        .padding(.horizontal)
    }
}

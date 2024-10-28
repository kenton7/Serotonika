//
//  RemindersScreen.swift
//  Relax
//
//  Created by Илья Кузнецов on 25.06.2024.
//

import SwiftUI
import FirebaseAuth
import CoreData
import FirebaseDatabase

struct Day {
    let name: String
    var isSelected: Bool = false
    var index: Int
}

struct RemindersScreen: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectionTime = Date()
    @State private var isDaySelected = false
    private let coreDataService = CoreDataService.shared
    @FetchRequest(sortDescriptors: []) var savedDays: FetchedResults<Reminder>
    @EnvironmentObject var notificationService: NotificationsService
    @StateObject private var databaseVM = ChangeDataInDatabase.shared
    @State private var selectedDays: [Day] = .init()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var yandexViewModel: YandexAuthorization
    @State private var isContinueOrSkipButtonPressed = false
    @State private var days: [Day] = [
            Day(name: "ПН", index: 2),
            Day(name: "ВТ", index: 3),
            Day(name: "СР", index: 4),
            Day(name: "ЧТ", index: 5),
            Day(name: "ПТ", index: 6),
            Day(name: "СБ", index: 7),
            Day(name: "ВС", index: 1)
        ]
    let isFromSettings: Bool
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        ScrollView {
            NavigationStack {
                VStack {
                    HStack {
                        Text("В какое время вам удобнее было бы медитировать?")
                            .padding(.horizontal)
                            .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255, green: 65/255, blue: 78/255, alpha: 1)))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Вы можете выбрать любое время, \nно мы советуем заниматься утром.")
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 161/255, green: 164/255, blue: 178/255, alpha: 1)))
                            .font(.system(size: 15, weight: .light, design: .rounded))
                        Spacer()
                    }
                    
                    DatePicker("", selection: $selectionTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .clipped()
                    
                    HStack {
                        Text("В какой день вам было бы удобнее медитировать?")
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255, green: 65/255, blue: 78/255, alpha: 1)))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Каждый день – это лучший вариант, \nно мы советуем выбрать как минимум \n5 дней в неделю.")
                            .padding(.horizontal)
                            .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 161/255, green: 164/255, blue: 178/255, alpha: 1)))
                            .font(.system(size: 15, weight: .light, design: .rounded))
                        Spacer()
                    }
                    
                    LazyHGrid(rows: [GridItem(.fixed(40))], 
                              alignment: .center,
                              spacing: 5,
                              content: {
                        ForEach($days, id: \.name) { $day in
                            Button(action: {
                                day.isSelected.toggle()
                                if day.isSelected {
                                    selectedDays.append(day)
                                } else {
                                    selectedDays.removeAll { $0.name == day.name }
                                }
                            }, label: {
                                Text(day.name)
                                    .foregroundColor(day.isSelected ? .white : Color(uiColor: .init(red: 161/255, green: 164/255, blue: 178/255, alpha: 1)))
                                    .frame(width: 40, height: 40)
                                    .font(.system(size: 15, weight: .light, design: .rounded))
                                    .background(day.isSelected ? Color(uiColor: .init(red: 63/255, green: 65/255, blue: 78/255, alpha: 1)) : Color.clear)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(uiColor: .init(red: 161/255, green: 164/255, blue: 178/255, alpha: 1)), lineWidth: 2)
                                    )
                                    .clipShape(Circle())
                            })
                            .padding(.horizontal, 3)
                        }
                    })
                    
                    VStack {
                        Spacer()
                        Button(action: {
                            notificationService.requestAuthorization()
                            coreDataService.saveSelectedDays(selectedDays, time: selectionTime)
                            notificationService.sendNotificationWithContent(title: "Медитация ждет вас!",
                                                                            subtitle: nil,
                                                                            body: "Найдите спокойное место и начните свою практику.",
                                                                            sound: .default,
                                                                            selectedDays: selectedDays,
                                                                            selectedTime: selectionTime)
                            if !isFromSettings {
                                if let firebaseUserID = Auth.auth().currentUser?.uid {
                                    databaseVM.writeToDatabaseIfUserViewedTutorial(userID: firebaseUserID, isViewed: true)
                                } else {
                                    databaseVM.writeToDatabaseIfUserViewedTutorial(userID: yandexViewModel.yandexUserID, isViewed: true)
                                    authViewModel.signedIn = true
                                    isContinueOrSkipButtonPressed = true
                                }
                            } else {
                                dismiss()
                            }
                        }, label: {
                            HStack {
                                Text("Сохранить")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                            }
                            .contentShape(.rect)
                        })
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .defaultButtonColor))
                        .clipShape(.rect(cornerRadius: 20))
                        .padding()
                        
                        if !isFromSettings {
                            Button(action: {
                                authViewModel.signedIn = true
                                coreDataService.saveSelectedDays(selectedDays, time: selectionTime)
                                isContinueOrSkipButtonPressed = true
                                if let firebaseUserID = Auth.auth().currentUser?.uid {
                                    databaseVM.writeToDatabaseIfUserViewedTutorial(userID: firebaseUserID, isViewed: true)
                                } else {
                                    databaseVM.writeToDatabaseIfUserViewedTutorial(userID: yandexViewModel.yandexUserID, isViewed: true)
                                }
                            }, label: {
                                Text("Нет, спасибо")
                                    .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .noThanksButtonColor))
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                            })
                        }
                    }
                }
                Spacer()
            }
            .padding(.bottom)
            .navigationDestination(isPresented: $isContinueOrSkipButtonPressed, destination: {
                CustomTabBar()
                    .navigationBarBackButtonHidden()
            })
            .onAppear {
                for savedDay in savedDays {
                    if let index = days.firstIndex(where: { $0.name == savedDay.day }) {
                        days[index].isSelected = savedDay.isSelected
                        if savedDay.isSelected {
                            selectedDays.append(days[index])
                        }
                    }
                    if let savedTime = savedDay.time {
                        selectionTime = savedTime
                    }
                }
            }
        }
    }
}

//#Preview {
//    RemindersScreen(isFromSettings: true)
//}

//
//  ChangeDataInDatabase.swift
//  Relax
//
//  Created by Илья Кузнецов on 04.07.2024.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import SwiftUI


protocol DatabaseChangable: AnyObject {
    func userLiked(course: CourseAndPlaylistOfDayModel, type: IncrementDecrementLike, isLiked: Bool, userID: String, courseType: Types)
    func updateListeners(course: CourseAndPlaylistOfDayModel, type: Types)
    func getListenersIn(course: CourseAndPlaylistOfDayModel, courseType: Types)
    func getLikesIn(course: CourseAndPlaylistOfDayModel, courseType: Types)
    func storyInfo(course: CourseAndPlaylistOfDayModel, isFemale: Bool)
    func checkIfUserLiked(userID: String, course: CourseAndPlaylistOfDayModel)
    func writeToDatabaseIfUserViewedTutorial(userID: String, isViewed: Bool)
    func checkIfUserViewedTutorial(userID: String) async -> Bool
    func updateDisplayName(newDisplayName: String) async throws
    func changeEmail(newEmail: String) async throws
    func updatePassword(newPassword: String, currentPassword: String) async throws
}

enum IncrementDecrementLike {
    case increment
    case decrement
}

final class ChangeDataInDatabase: ObservableObject, DatabaseChangable {
    
    @Published var likes = 0
    @Published var isLiked = false
    @Published var listeners = 0
    @Published var storyURL = ""
    @Published var isTutorialViewed: Bool = false
    private var authViewModel = AuthViewModel()
    @Published var isUpdatedListenets = false
    static let shared = ChangeDataInDatabase()
    var lastListenedCourseID: String?
    
    private init() {}
    
    public var isUserViewed: Bool {
        return isTutorialViewed != false
    }
    
    func userLiked(course: CourseAndPlaylistOfDayModel, type: IncrementDecrementLike, isLiked: Bool, userID: String, courseType: Types) {
        switch type {
        case .increment:
            likes += 1
            self.isLiked = true
            Database.database(url: .databaseURL).reference().child("users").child(userID).child("likedPlaylists").updateChildValues([course.name: self.isLiked])
        case .decrement:
            self.isLiked = false
            guard likes >= 1 else { return }
            likes -= 1
            Database.database(url: .databaseURL).reference().child("users").child(userID).child("likedPlaylists").child(course.name).removeValue()
        }
        
        switch courseType {
        case .playlist:
            Database.database(url: .databaseURL).reference().child("music").child(course.id).updateChildValues(["likes": likes])
        case .meditation:
            Database.database(url: .databaseURL).reference().child("courses").child(course.id).updateChildValues(["likes": likes])
        case .story:
            Database.database(url: .databaseURL).reference().child("nightStories").child(course.id).updateChildValues(["likes": likes])
        case .emergency:
            Database.database(url: .databaseURL).reference().child("emergencyMeditation").child(course.id).updateChildValues(["likes": likes])
        }
    }
    
    func userLiked(lesson: Lesson, type: IncrementDecrementLike, isLiked: Bool, userID: String) {
        switch type {
        case .increment:
            self.isLiked = true
            Database.database(url: .databaseURL).reference().child("users").child(userID).child("likedLessons").updateChildValues([lesson.name: self.isLiked])
        case .decrement:
            self.isLiked = false
            Database.database(url: .databaseURL).reference().child("users").child(userID).child("likedLessons").child(lesson.name).removeValue()
        }
    }
    
    func updateListeners(course: CourseAndPlaylistOfDayModel, type: Types) {
        // Проверяем, отличается ли выбранный курс от последнего прослушанного
        guard course.id != lastListenedCourseID else {
            print("Курс уже прослушивается, обновления не требуется.")
            return
        }
        
        var reference: DatabaseReference
        self.listeners += 1
        
        switch type {
        case .playlist:
            reference = Database.database(url: .databaseURL).reference().child("music").child(course.id)
        case .meditation:
            reference = Database.database(url: .databaseURL).reference().child("courses").child(course.id)
        case .story:
            reference = Database.database(url: .databaseURL).reference().child("nightStories").child(course.id)
        case .emergency:
            reference = Database.database(url: .databaseURL).reference().child("emergencyMeditation").child(course.id)
        }
        
        // Загружаем текущее значение
        reference.child("listenedCount").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self else { return }
            var currentListeners = snapshot.value as? Int ?? 0
            currentListeners += 1
            
            // Сохраняем увеличенное значение обратно в базу данных
                reference.updateChildValues(["listenedCount": currentListeners]) { error, _ in
                    if let error = error {
                        print("Ошибка при обновлении listenedCount: \(error)")
                    } else {
                        DispatchQueue.main.async {
                            self.listeners = currentListeners
                            print("Обновляем прослушивания. Стало: \(self.listeners)")
                            self.isUpdatedListenets = true
                            
                            // Обновляем идентификатор последнего прослушанного курса
                            self.lastListenedCourseID = course.id
                        }
                    }
            }
        }
    }
    
    func getListenersIn(course: CourseAndPlaylistOfDayModel, courseType: Types) {
        
        var path: String {
            switch courseType {
            case .playlist:
                "music"
            case .meditation:
                "courses"
            case .story:
                "nightStories"
            case .emergency:
                "emergencyMeditation"
            }
        }
        
        Database.database(url: .databaseURL).reference().child(path).child(course.id).child("listenedCount").observeSingleEvent(of: .value) { snapshot in
            if let listenersCount = snapshot.value as? Int {
                DispatchQueue.main.async {
                    self.listeners = listenersCount
                }
            } else {
                print("Значнние listenedCount не найдено для \(course.id) в \(path)")
            }
        }
    }
    
    func getLikesIn(course: CourseAndPlaylistOfDayModel, courseType: Types) {
        
        var path: String {
            switch courseType {
            case .playlist:
                "music"
            case .meditation:
                "courses"
            case .story:
                "nightStories"
            case .emergency:
                "emergencyMeditation"
            }
        }
        
        Database.database(url: .databaseURL).reference().child(path).child(course.id).child("likes").observeSingleEvent(of: .value) { snapshot in
            if let likesCount = snapshot.value as? Int {
                DispatchQueue.main.async {
                    self.likes = likesCount
                    print("Лайков у \(course.name) \(likesCount)")
                }
            } else {
                print("Значнние likes не найдено для \(course.id) в \(path)")
            }
        }
    }
    
    func storyInfo(course: CourseAndPlaylistOfDayModel, isFemale: Bool) {
        Database.database(url: .databaseURL).reference().child("nightStories").child(course.id).child("lessons").child("lesson1").child(isFemale ? "audioFemaleURL" : "audioMaleURL").observe(.value) { snapshot in
            if let url = snapshot.value as? String {
                DispatchQueue.main.async {
                    self.storyURL = url
                }
            } else {
                print("Не НАЙДЕНО")
            }
        }
    }
    
    func checkIfUserLiked(userID: String, course: CourseAndPlaylistOfDayModel) {
        let ref = Database.database(url: .databaseURL).reference()
        let likedPlaylistsRef = ref.child("users").child(userID).child("likedPlaylists")
        
        likedPlaylistsRef.observeSingleEvent(of: .value) { snapshot in
            if let likedPlaylists = snapshot.value as? [String: Bool] {
                if let isLiked = likedPlaylists[course.name] {
                    DispatchQueue.main.async {
                        self.isLiked = isLiked
                        print("Курс \(course.name) лайкнут? \(isLiked)")
                    }
                } else {
                    print("Значение для курса \(course.name) не найдено или не является Bool")
                    DispatchQueue.main.async {
                        self.isLiked = false
                    }
                }
            } else {
                print("Значения курсов не найдены или не в ожидаемом формате")
                DispatchQueue.main.async {
                    self.isLiked = false
                }
            }
        }
    }
    
    func writeToDatabaseIfUserViewedTutorial(userID: String, isViewed: Bool) {
        Database.database(url: .databaseURL).reference().child("users").child(userID).child("isTutorialViewed").setValue(isViewed)
        self.isTutorialViewed = true
    }
    
    func checkIfFirebaseUserViewedTutorial(userID: String) async {
        let ref = Database.database(url: .databaseURL).reference().child("users").child(userID).child("isTutorialViewed")
        ref.observeSingleEvent(of: .value) { snapshot in
            if let isViewed = snapshot.value as? Bool {
                DispatchQueue.main.async {
                    self.isTutorialViewed = isViewed
                    print("isTutorialViewed updated to: \(isViewed)")
                }
            } else {
                DispatchQueue.main.async {
                    self.isTutorialViewed = false
                    print("isTutorialViewed удалено или не найдено. isTutorialViewed = \(self.isTutorialViewed)")
                }
            }
        }
    }
    
    //    func checkIfFirebaseUserViewedTutorial(userID: String) {
    //        let ref = Database.database(url: .databaseURL).reference().child("users").child(userID).child("isTutorialViewed")
    //        ref.observeSingleEvent(of: .value) { snapshot in
    //            DispatchQueue.main.async {
    //                if let isViewed = snapshot.value as? Bool {
    //                    self.isTutorialViewed = isViewed
    //                } else {
    //                    self.isTutorialViewed = false
    //                }
    //            }
    //        }
    //    }
    
    
    func checkIfUserViewedTutorial(userID: String) async -> Bool {
        // Ссылка на путь в базе данных
        let ref = Database.database(url: .databaseURL).reference().child("users").child(userID).child("isTutorialViewed")
        
        // Используем сессию с async/await для получения данных
        do {
            // Получаем данные из базы данных
            let snapshot = try await ref.getData()
            
            // Преобразуем данные в Bool
            if let isViewed = snapshot.value as? Bool {
                // Возвращаем полученное значение
                print("isTutorialViewed updated to: \(isViewed)")
                return isViewed
            } else {
                // Возвращаем false, если данных нет или они не в формате Bool
                print("isTutorialViewed удалено или не найдено. isTutorialViewed = false")
                return false
            }
        } catch {
            // Обработка ошибки
            print("Error fetching data: \(error)")
            return false
        }
    }
    
    
    
    
    func updateDisplayName(newDisplayName: String) async throws {
        guard let user = Auth.auth().currentUser else {
            print("No user is signed in.")
            throw(NSError(domain: "Авторизованный пользователь не найден", code: 121))
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newDisplayName
        
        do {
            try await changeRequest.commitChanges()
        } catch {
            throw(NSError(domain: "Произошла ошибка при попытке изменения имени", code: 119))
        }
    }
    
    func changeEmail(newEmail: String) async throws {
        guard !newEmail.isEmpty, newEmail.isValidEmail() else {
            throw(NSError(domain: "Новое значение email введено неверно или не может быть пустым", code: 120, userInfo: ["Ошибка": ""]))
        }
        
        guard let user = Auth.auth().currentUser, !newEmail.isEmpty, newEmail.isValidEmail() else {
            print("No user is signed in.")
            throw(NSError(domain: "Авторизованный пользователь не найден", code: 121))
        }
        do {
            try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
        } catch {
            throw(error)
        }
    }
    
    func updatePassword(newPassword: String, currentPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            print("Пользователь не найден")
            throw(NSError(domain: "Авторизованный пользователь не найден", code: 121))
        }
        
        // Для повторной аутентификации используем метод EmailAuthProvider
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
        
        do {
            try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: newPassword)
            authViewModel.signOut()
        } catch {
            throw(NSError(domain: "Текущий пароль введён неверно", code: 122))
        }
    }
}


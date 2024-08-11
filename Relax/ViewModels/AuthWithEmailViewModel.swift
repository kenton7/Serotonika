//
//  AuthWithEmail.swift
//  Relax
//
//  Created by Илья Кузнецов on 21.06.2024.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import UserNotifications

protocol Authable: AnyObject {
    func asyncRegisterWith(name: String, email: String, password: String) async throws
    func asyncLogInWith(email: String, password: String) async throws
    func restorePasswordWith(email: String, completion: @escaping ((Bool, NSError?) -> Void))
    func signOut()
    func deleteAccount()
}

final class AuthWithEmailViewModel: ObservableObject, Authable {
    
    @Published var signedIn = false
    @Published var userID: String = ""
    private var handler: AuthStateDidChangeListenerHandle?
    
    public var isUserLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    func asyncRegisterWith(name: String, email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            await MainActor.run {
                //self.signedIn = true
                self.userID = result.user.uid
            }
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            let userData = ["email": email, "name": name]
            try await Database.database(url: .databaseURL).reference().child("users").child(result.user.uid).setValue(userData)
        } catch {
            let errorCodes = AuthErrorCode(_nsError: error as NSError)
            let customError: NSError
            
            switch errorCodes.code {
            case .invalidEmail:
                customError = NSError(domain: "FirebaseAuth",
                                      code: errorCodes.errorCode,
                                      userInfo: [NSLocalizedDescriptionKey: "Введён некорректный email."])
            case .emailAlreadyInUse:
                customError = NSError(domain: "FirebaseAuth",
                                      code: errorCodes.errorCode,
                                      userInfo: [NSLocalizedDescriptionKey: "Пользователь с таким email уже зарегистрирован."])
            case .weakPassword:
                customError = NSError(domain: "FirebaseAuth",
                                      code: errorCodes.errorCode,
                                      userInfo: [NSLocalizedDescriptionKey: "Пароль должен быть длиной минимум в 6 символов."])
            default:
                customError = NSError(domain: "FirebaseAuth",
                                      code: errorCodes.errorCode,
                                      userInfo: [NSLocalizedDescriptionKey: "Неизвестная ошибка: \(error.localizedDescription)"])
            }
            throw customError
        }
    }
    
    func asyncLogInWith(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await MainActor.run {
                self.signedIn = true
                self.userID = result.user.uid
            }
            print("User logged in with ID: \(userID)")
        } catch {
            let errorCodes = AuthErrorCode(_nsError: error as NSError)
            let customError: NSError
            
            switch errorCodes.code {
            case .invalidEmail:
                customError = NSError(domain: "FirebaseAuth",
                                      code: errorCodes.errorCode,
                                      userInfo: [NSLocalizedDescriptionKey: "Введён неверный email."])
            case .wrongPassword:
                customError = NSError(domain: "FirebaseAuth",
                                      code: errorCodes.errorCode,
                                      userInfo: [NSLocalizedDescriptionKey: "Введён неверный пароль."])
            case .userNotFound:
                customError = NSError(domain: "FirebaseAuth",
                                      code: errorCodes.errorCode,
                                      userInfo: [NSLocalizedDescriptionKey: "Пользователь не найден."])
            case .invalidCredential:
                customError = NSError(domain: "FirebaseAuth",
                                      code: errorCodes.errorCode,
                                      userInfo: [NSLocalizedDescriptionKey: "Пользователь не найден."])
            default:
                print(error)
                customError = NSError(domain: "FirebaseAuth",
                                      code: errorCodes.errorCode,
                                      userInfo: [NSLocalizedDescriptionKey: "Неверный email или пароль."])
            }
            throw customError
        }
    }
    
    func restorePasswordWith(email: String, completion: @escaping ((Bool, NSError?) -> Void)) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if error != nil {
                DispatchQueue.main.async {
                    completion(false, error as NSError?)
                }
            } else {
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.signedIn = false
                self.userID = ""
                print("Пользователь вышел из системы. signedIn: \(self.signedIn), userID: \(self.userID)")
            }
        } catch {
            print("Ошибка при попытке выхода из аккаунта: \(error.localizedDescription)")
        }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("User signed out")
    }
    
    func deleteAccount() {
        Database.database(url: .databaseURL).reference().child("users").child(Auth.auth().currentUser!.uid).removeValue()
        Auth.auth().currentUser?.delete(completion: { error in
            if let error = error {
                print(error)
            } else {
                DispatchQueue.main.async {
                    self.signedIn = false
                    self.userID = ""
                }
            }
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        })
    }
}

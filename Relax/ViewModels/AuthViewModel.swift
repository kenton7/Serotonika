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
import AuthenticationServices
import CryptoKit

protocol Authable: AnyObject {
    func asyncRegisterWith(name: String, email: String, password: String) async throws
    func asyncLogInWith(email: String, password: String) async throws
    func restorePasswordWith(email: String, completion: @escaping ((Bool, NSError?) -> Void))
    func signOut()
    func deleteAccount()
}

final class AuthViewModel: NSObject, ObservableObject, Authable {
    
    @Published var signedIn = false
    @Published var isAppleLogin = false
    @Published var userID: String = ""
    @Published var appleIDEmail: String = ""
    //private var databaseVM = ChangeDataInDatabase()
    private var notificationsService = NotificationsService.shared
    var currentNonce: String?
    
    public var isUserLoggedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    func asyncRegisterWith(name: String, email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            await MainActor.run {
                self.userID = result.user.uid
            }
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            let userData = ["email": email, "name": name]
            try await Database.database(url: .databaseURL).reference().child("users").child(result.user.uid).setValue(userData)
        } catch {
            let authError = AuthErrorCode(rawValue: error._code)
            let errorMessage = authError?.errorMessage ?? "Произошла неизвестная ошибка."
            throw(NSError(domain: "", code: error._code, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
        }
    }
    
    func asyncLogInWith(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await MainActor.run {
                self.signedIn = true
                self.userID = result.user.uid
            }
        } catch {
            let authError = AuthErrorCode(rawValue: error._code)
            let errorMessage = authError?.errorMessage ?? "Произошла неизвестная ошибка."
            throw(NSError(domain: "", code: error._code, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
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
    
    //MARK: - Apple Sign In Methods
    func signInWithApple(_ authorization: ASAuthorization) async {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            let nonce = randomNonceString()
            self.currentNonce = sha256(nonce)
            
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)

            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error {
                    print(error.localizedDescription)
                    return
                }
                if let userID = Auth.auth().currentUser?.uid {
                    self.userID = userID
                    self.signedIn = true

                    Task {
                        await ChangeDataInDatabase.shared.checkIfFirebaseUserViewedTutorial(userID: self.userID)
                    }
                    Database.database(url: .databaseURL).reference().child("users").child(userID).child("email").setValue(Auth.auth().currentUser?.email ?? "")
                    Database.database(url: .databaseURL).reference().child("users").child(userID).child("name").setValue(Auth.auth().currentUser?.displayName ?? "")
                    self.notificationsService.rescheduleNotifications()
                } else {
                    print("Firebase sign in succeeded, but no user ID was returned.")
                }
            }
        }
    }
    
    func revokeAppleSignInToken() {
        // Проверяем, что пользователь авторизован
        guard let _ = Auth.auth().currentUser else {
            print("No user is currently signed in.")
            return
        }
        
        // Повторная аутентификация для получения нового токена
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.signedIn = false
                self.userID = ""
                self.currentNonce = nil
                ChangeDataInDatabase.shared.isTutorialViewed = false
                print("Пользователь вышел из системы. signedOut: \(self.signedIn), userID: \(self.userID)")
            }
        } catch {
            print("Ошибка при попытке выхода из аккаунта: \(error.localizedDescription)")
        }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("User signed out")
    }
    
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        Database.database(url: .databaseURL).reference().child("users").child(user.uid).removeValue()
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

extension AuthViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
        else {
            print("Unable to retrieve AppleIDCredential")
            return
        }
        
        guard let _ = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        
        guard let appleAuthCode = appleIDCredential.authorizationCode else {
            print("Unable to fetch authorization code")
            return
        }
        
        guard let authCodeString = String(data: appleAuthCode, encoding: .utf8) else {
            print("Unable to serialize auth code string from data: \(appleAuthCode.debugDescription)")
            return
        }
        
        Task {
            do {
                guard let userID = Auth.auth().currentUser?.uid else { return }
                
                try await Database.database(url: .databaseURL).reference().child("users").child(userID).removeValue()
                try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
                try await Auth.auth().currentUser?.delete()
                await MainActor.run {
                    self.signedIn = false
                    self.userID = ""
                    self.currentNonce = nil
                    ChangeDataInDatabase.shared.isTutorialViewed = false
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple error: \(error.localizedDescription)")
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding Method
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        //return UIApplication.shared.windows.first!
        return UIWindow()
    }
}

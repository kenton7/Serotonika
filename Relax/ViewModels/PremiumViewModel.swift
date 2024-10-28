//
//  PremiumViewModel.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 24.08.2024.
//

import Foundation
import StoreKit
import FirebaseDatabase
import FirebaseAuth

public enum StoreError: Error {
    case failedVerification
}

@MainActor
class PremiumViewModel: ObservableObject {
    
    typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionGroupStatus: RenewalState?
    var hasUnlockedPremuim: Bool {
        return !purchasedSubscriptions.isEmpty
    }
    @Published var isPremium = false
    
    private let productsIDs = ["monthly.subscription.serotonika.com", "yearly.subscription.serotonika.com"]
    var updateListenerTask: Task<Void, Error>? = nil
    
    static let shared = PremiumViewModel()
    private let yandexViewModel = YandexAuthorization.shared
    
    private init() {
        updateListenerTask = listenerForTransactions()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func listenerForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    _ = try await self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                } catch {
                    print("Transaction failed verifiacation: \(error)")
                }
            }
        }
    }
    
    @MainActor
    func requestProducts() async {
        do {
            subscriptions = try await Product.products(for: productsIDs)
        } catch {
            print("Error fetching products from App Store server: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        print("Начало процесса покупки для продукта \(product.displayName)")
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            print("Покупка успешна, верификация начинается для продукта \(product.displayName)")
            let transaction = try checkVerified(verificationResult)
            await transaction.finish()
            print("Транзакция завершена, вызываем обновление статуса")
            await updateCustomerProductStatus()
            print("Транзакция завершена для продукта \(product.displayName)")
            
            if Auth.auth().currentUser?.uid != nil || !yandexViewModel.yandexUserID.isEmpty {
                try await Database.database(url: .databaseURL).reference().child("users").child(Auth.auth().currentUser?.uid ?? yandexViewModel.yandexUserID).child("isPremium").setValue(hasUnlockedPremuim)
                print("Премиум обновлен в базе данных")
            }
            return transaction
        case .userCancelled:
            print("Пользователь отменил покупку")
            return nil
        case .pending:
            print("Покупка ожидается")
            return nil
        @unknown default:
            print("Неизвестный результат покупки")
            return nil
        }
    }

    
    func checkVerified<T>(_ verificationResult: VerificationResult<T>) throws -> T {
        switch verificationResult {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        print("Начало обновления статуса продуктов")

        for await result in Transaction.currentEntitlements {
            print("Текущие привилегии транзакции: \(result)")
            do {
                print("Обрабатываем результат транзакции")
                let transaction = try checkVerified(result)
                print("Транзакция проверена: \(transaction.productID)")

                switch transaction.productType {
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        print("Найдена подписка: \(subscription.displayName)")
                        purchasedSubscriptions.append(subscription)
                    }
                default:
                    break
                }
                await transaction.finish()
                print("Транзакция завершена: \(transaction.productID)")
            } catch {
                print("Ошибка при обновлении статуса продуктов: \(error)")
            }
        }

        print("Обновление статуса продуктов завершено")
    }

    
    //--------
//    let productsIDs = ["monthly.subscription.serotonika.com", "yearly.subscription.serotonika.com"]
//    @Published private(set) var products: [Product] = []
//    @Published private(set) var purchasedProductsIDs = Set<String>()
//    private let yandexViewModel = YandexAuthorization.shared
//    
//    private var productsLoaded = false
//    static let shared = PremiumViewModel()
//    
//    var hasUnlockedPremuim: Bool {
//        return !purchasedProductsIDs.isEmpty
//    }
//    
//    private var updates: Task<Void, Never>? = nil
//    
//    private init() {
//        updates = observeTransactionUpdates()
//    }
//    
//    deinit {
//        updates?.cancel()
//    }
//    
//    func checkPremium() -> Bool {
//        return hasUnlockedPremuim
//    }
//
//    func loadProducts() async throws {
//        guard !productsLoaded else {
//            print("Продукты уже загружены")
//            return
//        }
//        
//        do {
//            let storeProducts = try await Product.products(for: productsIDs)
//            // Убедитесь, что продукты не пусты
//            guard !storeProducts.isEmpty else {
//                print("Не удалось загрузить продукты: список пуст")
//                return
//            }
//            // Продукты успешно загружены
//            products = storeProducts
//            productsLoaded = true
//            print("Продукты успешно загружены: \(products)")
//        } catch {
//            print("Ошибка при загрузке продуктов: \(error.localizedDescription)")
//            throw error
//        }
//    }
//    
//    func purchase(_ product: Product) async throws {
//        do {
//            let result = try await product.purchase()
//            
//            switch result {
//            case let .success(.verified(transaction)):
//                print("Успешная покупка для productID: \(transaction.productID), завершаем транзакцию...")
//                await updatePurchasedProducts()
//                await transaction.finish()
//                
//                if Auth.auth().currentUser?.uid != nil || !yandexViewModel.yandexUserID.isEmpty {
//                    try await Database.database(url: .databaseURL).reference().child("users").child(Auth.auth().currentUser?.uid ?? yandexViewModel.yandexUserID).child("isPremium").setValue(hasUnlockedPremuim)
//                }
//            case let .success(.unverified(_, error)):
//                print("Неподтвержденная покупка для productID: \(product.id), ошибка: \(error.localizedDescription)")
//            case .pending:
//                print("Ожидающая транзакция для productID: \(product.id)...")
//            case .userCancelled:
//                print("Пользователь отменил покупку для productID: \(product.id).")
//            @unknown default:
//                print("Неизвестный статус для productID: \(product.id).")
//            }
//        } catch {
//            print("Ошибка при покупке продукта: \(error.localizedDescription)")
//            throw error
//        }
//    }
//    
//    func updatePurchasedProducts() async {
//        print("Обновление купленных продуктов...")
//
//        purchasedProductsIDs.removeAll() // Сбрасываем перед обновлением
//
//        for await result in Transaction.currentEntitlements {
//            switch result {
//            case .verified(let transaction):
//                print("Проверенная транзакция найдена для productID: \(transaction.productID)")
//                
//                // Проверяем, что транзакция активна и не была отозвана
//                if transaction.revocationDate == nil {
//                    purchasedProductsIDs.insert(transaction.productID)
//                    print("ProductID \(transaction.productID) добавлен в purchasedProductsIDs.")
//                } else {
//                    print("Транзакция для productID \(transaction.productID) была отозвана или истекла.")
//                    purchasedProductsIDs.remove(transaction.productID)
//                }
//            case .unverified(_, let error):
//                print("Непроверенная транзакция с ошибкой: \(error.localizedDescription)")
//            }
//        }
//        
//        print("Финальный список purchasedProductsIDs: \(purchasedProductsIDs)")
//
//        do {
//            if Auth.auth().currentUser?.uid != nil || !yandexViewModel.yandexUserID.isEmpty {
//                try await Database.database(url: .databaseURL).reference().child("users").child(Auth.auth().currentUser?.uid ?? yandexViewModel.yandexUserID).child("isPremium").setValue(hasUnlockedPremuim)
//            }
//        } catch {
//            print("Ошибка при обновлении isPremium в базе данных: \(error)")
//        }
//    }
//
//    @MainActor
//    func refreshProducts() async {
//        do {
//            productsLoaded = false // Сброс кеша загруженных продуктов
//            try await loadProducts() // Перезагрузка списка продуктов
//        } catch {
//            print("Ошибка при обновлении продуктов: \(error.localizedDescription)")
//        }
//    }
//
//    private func observeTransactionUpdates() -> Task<Void, Never> {
//        Task(priority: .background) { [unowned self] in
//            for await result in Transaction.updates {
//                print("Обновление транзакции обнаружено: \(result)")
//                await updatePurchasedProducts() // Обновляем транзакции
//                await refreshProducts() // Обновляем продукты только при изменении транзакций
//            }
//        }
//    }
}


//
//  Yandex.swift
//  Relax
//
//  Created by Илья Кузнецов on 15.08.2024.
//

import Foundation

struct YandexPhoneNumber: Codable {
    let id: Int?
    let number: String?
}


struct YandexUserInfo: Codable {
    let id: String
    let login: String
    let emails: [String]?
    let first_name: String?
    let last_name: String?
    let display_name: String?
    let real_name: String?
    let client_id: String?
    let sex: String?
   // let default_phone: YandexPhoneNumber
}

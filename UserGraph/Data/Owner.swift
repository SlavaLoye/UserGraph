//
//  Owner.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import Foundation
import SwiftData

@Model
final class Owner {
    @Attribute(.unique) var id: UUID
    var email: String        // синхронизируем с Session.email
    var username: String
    var sex: String          // например: "male", "female", "other"
    var birthDate: Date
    var avatarURL: URL?      // локальный URL сохранённого изображения

    var createdAt: Date
    var updatedAt: Date

    init(email: String,
         username: String = "",
         sex: String = "",
         birthDate: Date = Date(timeIntervalSince1970: 0),
         avatarURL: URL? = nil) {
        self.id = UUID()
        self.email = email
        self.username = username
        self.sex = sex
        self.birthDate = birthDate
        self.avatarURL = avatarURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isFilled: Bool {
        // Минимальные критерии заполненности
        !email.isEmpty && !username.isEmpty && !sex.isEmpty && birthDate > Date(timeIntervalSince1970: 0)
    }
}

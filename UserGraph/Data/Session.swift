//
//  Session.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var email: String
    var isLoggedIn: Bool
    var createdAt: Date

    init(email: String, isLoggedIn: Bool) {
        self.id = UUID()
        self.email = email
        self.isLoggedIn = isLoggedIn
        self.createdAt = Date()
    }
}

//
//  User.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: Int
    var sex: String
    var username: String
    var isOnline: Bool
    var age: Int
    @Relationship(deleteRule: .cascade) var files: [UserFile]

    init(id: Int, sex: String, username: String, isOnline: Bool, age: Int, files: [UserFile]) {
        self.id = id
        self.sex = sex
        self.username = username
        self.isOnline = isOnline
        self.age = age
        self.files = files
    }
}

@Model
final class UserFile {
    @Attribute(.unique) var id: Int
    var url: URL
    var type: String

    init(id: Int, url: URL, type: String) {
        self.id = id
        self.url = url
        self.type = type
    }
}

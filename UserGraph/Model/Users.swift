//
//  Untitled.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import Foundation

struct UsersEnvelope: Decodable {
    let users: [UserDTO]
}

struct UserDTO: Decodable {
    let id: Int
    let sex: String
    let username: String
    let isOnline: Bool
    let age: Int
    let files: [UserFileDTO]
}

struct UserFileDTO: Decodable {
    let id: Int
    let url: URL
    let type: String
}

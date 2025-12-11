//
//  APIClient.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import Foundation

struct APIClient {
    var baseURL: URL = URL(string: "http://test-case.rikmasters.ru")!

    func fetchUsers() async throws -> [UserDTO] {
        let url = baseURL.appending(path: "/api/episode/users/")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(UsersEnvelope.self, from: data)
        return decoded.users
    }
}

// MARK: - DTOs

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

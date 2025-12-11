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

        // Validate HTTP status
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            // Map common HTTP failures
            switch http.statusCode {
            case 401: throw URLError(.userAuthenticationRequired)
            case 403: throw URLError(.noPermissionsToReadFile)
            case 404: throw URLError(.fileDoesNotExist)
            case 408: throw URLError(.timedOut)
            case 500...599: throw URLError(.badServerResponse)
            default: throw URLError(.badServerResponse)
            }
        }

        // Optional: Validate Content-Type contains "application/json"
        if let contentType = http.value(forHTTPHeaderField: "Content-Type"),
           contentType.lowercased().contains("json") == false {
            // Not fatal if server omits header; only throw if clearly wrong
            // throw URLError(.cannotParseResponse)
        }

        let decoder = JSONDecoder()
        // If backend uses snake_case keys, this will map them to camelCase properties.
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // Keep default strategies otherwise.
        let envelope = try decoder.decode(UsersEnvelope.self, from: data)
        return envelope.users
    }
}

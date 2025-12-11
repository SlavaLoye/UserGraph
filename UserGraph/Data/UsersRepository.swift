//
//  UsersRepository.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import Foundation
import SwiftData

@MainActor
final class UsersRepository {
    private let context: ModelContext
    private let api: APIClient

    init(context: ModelContext, api: APIClient = .init()) {
        self.context = context
        self.api = api
    }

    // Возвращает локальные данные, если есть. Если пусто и allowNetworkIfEmpty = true — тянет из сети и сохраняет.
    func users(allowNetworkIfEmpty: Bool = true) async throws -> [User] {
        let descriptor = FetchDescriptor<User>()
        let cached = try context.fetch(descriptor)
        if !cached.isEmpty || !allowNetworkIfEmpty {
            return cached
        }
        return try await refreshUsers()
    }

    // Принудительное обновление
    func refreshUsers() async throws -> [User] {
        let dtos = try await api.fetchUsers()
        // Очистим текущие записи и перезапишем (upsert по id тоже возможен)
        try deleteAllUsers()

        for dto in dtos {
            let files = dto.files.map { UserFile(id: $0.id, url: $0.url, type: $0.type) }
            let model = User(id: dto.id,
                             sex: dto.sex,
                             username: dto.username,
                             isOnline: dto.isOnline,
                             age: dto.age,
                             files: files)
            context.insert(model)
        }
        try context.save()
        let descriptor = FetchDescriptor<User>()
        return try context.fetch(descriptor)
    }

    private func deleteAllUsers() throws {
        let descriptor = FetchDescriptor<User>()
        let all = try context.fetch(descriptor)
        for u in all {
            context.delete(u)
        }
    }
}

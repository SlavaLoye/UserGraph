//
//  UserGraphApp.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI
import SwiftData

@main
struct UserGraphApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            User.self,
            UserFile.self,
            Owner.self // ВАЖНО: добавить Owner в схему
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

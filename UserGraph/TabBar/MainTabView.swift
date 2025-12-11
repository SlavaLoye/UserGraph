//
//  MainTabView.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // Общий фон приложения
            Theme.backgroundGradient(for: scheme)
                .ignoresSafeArea()

            // Декоративные «световые пятна» (мягко, чтобы не мешали)
            ZStack {
                Circle()
                    .fill(Theme.glow1)
                    .blur(radius: 120)
                    .frame(width: 340, height: 340)
                    .offset(x: -150, y: -420)

                Circle()
                    .fill(Theme.glow2)
                    .blur(radius: 140)
                    .frame(width: 360, height: 360)
                    .offset(x: 170, y: 520)
            }
            .allowsHitTesting(false)

            // Контент табов
            TabView {
                StatsPlaceholderView()
                    .tabItem {
                        Label("График", systemImage: "chart.line.uptrend.xyaxis")
                    }

                UsersView()
                    .tabItem {
                        Label("Юзеры", systemImage: "person.3")
                    }

                ProfileView()
                    .tabItem {
                        Label("Профиль", systemImage: "person.crop.circle")
                    }
            }
            // Акцент таббара — из Theme
            .tint(Theme.accent)
        }
    }
}

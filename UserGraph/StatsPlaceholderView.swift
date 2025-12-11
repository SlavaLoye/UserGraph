//
//  StatsPlaceholderView.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI
import SwiftData

struct StatsPlaceholderView: View {
    @Environment(\.colorScheme) private var scheme

    // Берём пользователей из SwiftData и используем первых трёх
    @Query(sort: \User.username, order: .forward, animation: .default)
    private var allUsers: [User]

    private var topVisitors: [User] {
        Array(allUsers.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        // Карточка с «псевдо-графиком» (заглушка)
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(Theme.accent.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .foregroundStyle(Theme.accent)
                                    }
                                    Text("Статистика")
                                        .font(.headline)
                                        .foregroundStyle(.white) // заголовок — белый
                                }

                                // Имитация столбиков (скелетон)
                                HStack(alignment: .bottom, spacing: 10) {
                                    ForEach(sampleBars, id: \.self) { h in
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Theme.accent.opacity(0.35))
                                            .frame(width: 16, height: CGFloat(h))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)

                                Text("Скоро подключим реальные данные из /api/episode/statistics/")
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.85)) // подпись — полубелая
                            }
                        }

                        // Топ‑посетители (заглушка: первые 3 пользователя)
                        if !topVisitors.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Чаще всех посещают ваш профиль")
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    VStack(spacing: 10) {
                                        ForEach(topVisitors, id: \.id) { user in
                                            NavigationLink {
                                                UserDetailView(user: user)
                                            } label: {
                                                TopVisitorRow(user: user)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }

                        // Ещё одна карточка‑плейсхолдер
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Пол и возраст")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("Сегодня • Сегменты появятся позже.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Статистика")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white) // титул — белый
                }
            }
        }
    }

    // Примерные высоты столбиков для скелетона
    private var sampleBars: [CGFloat] { [24, 48, 32, 60, 42, 72, 38, 56, 28, 64] }
}

// Ряд в списке «топ‑посетителей»
private struct TopVisitorRow: View {
    let user: User
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: user.files.first(where: { $0.type == "avatar" })?.url)
                .frame(width: 44, height: 44)
                .shadow(color: Theme.cardShadow(for: scheme).opacity(0.45), radius: 8, x: 0, y: 5)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.username)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if user.isOnline {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                    }
                }

                Text("Возраст: \(user.age) • Пол: \(user.sex)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.glassStroke(for: scheme), lineWidth: 1)
                )
        )
    }
}

// Универсальная стеклянная карточка в стиле Theme
private struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.glassFill())
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Theme.glassStroke(for: scheme), lineWidth: 1)
                    )
            )
            .shadow(color: Theme.cardShadow(for: scheme), radius: 20, x: 0, y: 12)
    }
}

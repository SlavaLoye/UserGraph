//
//  UsersView.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI
import SwiftData

struct UsersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \User.username, order: .forward, animation: .default)
    private var users: [User]

    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                Group {
                    if isLoading && users.isEmpty {
                        ProgressView("Загрузка...")
                            .tint(.white)
                            .foregroundStyle(.white)
                            .padding()
                    } else if let errorMessage, users.isEmpty {
                        VStack(spacing: 12) {
                            Text(errorMessage)
                                .foregroundStyle(.white)
                            Button("Повторить") { Task { await load(initial: true) } }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(users) { user in
                                    NavigationLink {
                                        UserDetailView(user: user)
                                    } label: {
                                        UserCard(user: user)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .refreshable { await refresh() }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Пользователи")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white) // титул — белый
                }
            }
        }
        .task { await load(initial: true) }
    }

    private func load(initial: Bool) async {
        await setLoading(true)
        defer { Task { await setLoading(false) } }

        let repo = UsersRepository(context: modelContext)
        do {
            _ = try await repo.users(allowNetworkIfEmpty: true)
            errorMessage = nil
        } catch {
            if users.isEmpty {
                errorMessage = "Не удалось загрузить пользователей"
            }
        }
    }

    private func refresh() async {
        await setLoading(true)
        defer { Task { await setLoading(false) } }

        let repo = UsersRepository(context: modelContext)
        do {
            _ = try await repo.refreshUsers()
            errorMessage = nil
        } catch {
            errorMessage = "Ошибка обновления"
        }
    }

    @MainActor private func setLoading(_ value: Bool) {
        isLoading = value
    }
}

private struct UserCard: View {
    let user: User
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(url: user.files.first(where: { $0.type == "avatar" })?.url)
                .frame(width: 56, height: 56)
                .shadow(color: Theme.cardShadow(for: scheme).opacity(0.55), radius: 10, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(user.username)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white) // имя — белое
                        .lineLimit(1)

                    if user.isOnline {
                        HStack(spacing: 6) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text("online")
                                .font(.caption).bold()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(colors: [Color.green.opacity(0.85), Color.green.opacity(0.65)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        )
                        .foregroundStyle(.white)
                    }
                }

                Text("Возраст: \(user.age) • Пол: \(user.sex)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85)) // второстепенный — полубелый
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.glassFill())
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.glassStroke(for: scheme), lineWidth: 1)
                )
        )
        .shadow(color: Theme.cardShadow(for: scheme), radius: 16, x: 0, y: 10)
    }
}

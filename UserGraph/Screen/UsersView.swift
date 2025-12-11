//
//  UsersView.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI
import SwiftData

struct UsersView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext

    // Load users sorted by username
    @Query(sort: \User.username, order: .forward, animation: .default)
    private var users: [User]

    @State private var isRefreshing = false
    @State private var initialLoadDone = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                // Контент
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let errorMessage {
                            ErrorCard(message: errorMessage) {
                                Task { await reload(showSpinner: true) }
                            }
                            .padding(.top, 16)
                        }

                        if users.isEmpty && initialLoadDone {
                            EmptyStateCard(
                                title: "Пользователи не найдены",
                                systemImage: "person.3"
                            )
                            .padding(.top, 24)
                        } else {
                            ForEach(users, id: \.id) { user in
                                NavigationLink {
                                    UserDetailView(user: user)
                                } label: {
                                    UserRow(user: user)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                // pull-to-refresh: системное колесико появится в области overscroll
                .refreshable {
                    await reload(showSpinner: false)
                }

                // Явный индикатор поверх — виден всегда, даже если overscroll короткий
                if isRefreshing {
                    ProgressOverlay()
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Юзеры")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await reload(showSpinner: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.white)
                    }
                    .disabled(isRefreshing)
                    .opacity(isRefreshing ? 0.6 : 1.0)
                }
            }
        }
        .task {
            // Первичная загрузка: если локально пусто — подтянуть из сети
            await initialLoadIfNeeded()
        }
    }

    // MARK: - Loading

    private func repository() -> UsersRepository {
        UsersRepository(context: modelContext)
    }

    private func initialLoadIfNeeded() async {
        guard !initialLoadDone else { return }
        do {
            _ = try await repository().users(allowNetworkIfEmpty: true)
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось загрузить пользователей"
        }
        initialLoadDone = true
    }

    private func reload(showSpinner: Bool) async {
        await MainActor.run {
            if showSpinner { isRefreshing = true }
            errorMessage = nil
        }
        do {
            _ = try await repository().refreshUsers()
        } catch {
            await MainActor.run {
                errorMessage = "Ошибка обновления. Потяните вниз, чтобы повторить."
            }
        }
        await MainActor.run {
            isRefreshing = false
            initialLoadDone = true
        }
    }
}

private struct UserRow: View {
    let user: User
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: user.files.first(where: { $0.type == "avatar" })?.url)
                .frame(width: 48, height: 48)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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

private struct EmptyStateCard: View {
    let title: String
    let systemImage: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.glassFill())
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Theme.glassStroke(for: scheme), lineWidth: 1)
                )
        )
        .shadow(color: Theme.cardShadow(for: scheme), radius: 18, x: 0, y: 10)
    }
}

private struct ErrorCard: View {
    let message: String
    let retry: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.title2.weight(.bold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Label("Повторить", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Theme.primaryButtonGradient()
                            .clipShape(Capsule())
                    )
                    .shadow(color: Theme.primaryButtonShadow, radius: 8, x: 0, y: 6)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.glassFill())
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Theme.glassStroke(for: scheme), lineWidth: 1)
                )
        )
        .shadow(color: Theme.cardShadow(for: scheme), radius: 18, x: 0, y: 10)
    }
}

private struct ProgressOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .transition(.opacity)
    }
}

//
//  ProfileView.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.createdAt, order: .forward, animation: .default)
    private var sessions: [Session]
    @Query private var owners: [Owner]

    @State private var isPresentingSetup = false

    init() {
        _owners = Query()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let session = sessions.first, session.isLoggedIn {
                        let owner = ownerFor(session.email)

                        ProfileHeaderCard(owner: owner)

                        InfoCard {
                            HStack {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(session.email.isEmpty ? "—" : session.email)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }

                        VStack(spacing: 14) {
                            Button {
                                isPresentingSetup = true
                            } label: {
                                GradientButtonLabel(title: owner == nil ? "Заполнить профиль" : "Редактировать профиль",
                                                    systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                logout()
                            } label: {
                                DestructiveButtonLabel(title: "Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                        .padding(.top, 6)
                    } else {
                        EmptyStateCard(
                            title: "Войдите, чтобы увидеть профиль",
                            systemImage: "person.crop.circle.badge.exclam"
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(
                Theme.backgroundGradient(for: .dark)
                    .ignoresSafeArea()
            )
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Профиль")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $isPresentingSetup) {
            if let email = sessions.first?.email {
                NavigationStack {
                    OwnerSetupView(email: email)
                }
            }
        }
    }

    private func ownerFor(_ email: String) -> Owner? {
        let descriptor = FetchDescriptor<Owner>(predicate: #Predicate { $0.email == email })
        return (try? modelContext.fetch(descriptor))?.first
    }

    private func logout() {
        if let s = sessions.first {
            s.isLoggedIn = false
            try? modelContext.save()
        }
    }
}

private struct ProfileHeaderCard: View {
    let owner: Owner?

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Мягкий круговой «ореол» за аватаром
                Circle()
                    .fill(LinearGradient(colors: [
                        Theme.accent.opacity(0.25),
                        .clear
                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .blur(radius: 40)
                    .frame(width: 240, height: 240)

                // Аватар с красивым кольцом
                ZStack {
                    // Внешнее свечение
                    Circle()
                        .fill(Theme.accent.opacity(0.25))
                        .frame(width: 184, height: 184)
                        .blur(radius: 18)

                    // Градиентное кольцо
                    Circle()
                        .strokeBorder(
                            LinearGradient(colors: [Theme.accent, .white.opacity(0.9)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 3
                        )
                        .frame(width: 172, height: 172)
                        .opacity(0.9)

                    // Сам аватар
                    AvatarView(url: owner?.avatarURL)
                        .frame(width: 164, height: 164)
                        .shadow(color: Theme.cardShadow(for: scheme).opacity(0.6), radius: 14, x: 0, y: 8)
                }
            }
            .frame(maxWidth: .infinity)

            Text(owner?.username.isEmpty == false ? (owner?.username ?? "—") : "Без имени")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Label(owner?.sex.isEmpty == false ? (owner?.sex ?? "—") : "—", systemImage: "person")
                Text("•").foregroundStyle(.white.opacity(0.7))
                Label(formattedDate(owner?.birthDate), systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.9))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            // Более «стеклянная» карточка без ощущения «тяжёлого квадрата»
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.glassFill())
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Theme.glassStroke(for: scheme), lineWidth: 1)
                )
        )
        .shadow(color: Theme.cardShadow(for: scheme).opacity(0.6), radius: 20, x: 0, y: 12)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
}

private struct InfoCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
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

private struct GradientButtonLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.semibold)
        }
        .font(.headline)
        .foregroundStyle(.white)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            Theme.primaryButtonGradient()
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .shadow(color: Theme.primaryButtonShadow, radius: 12, x: 0, y: 8)
    }
}

private struct DestructiveButtonLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.semibold)
        }
        .font(.headline)
        .foregroundStyle(.white)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            Theme.destructiveButtonGradient()
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .shadow(color: Theme.destructiveButtonShadow, radius: 12, x: 0, y: 8)
    }
}

private struct EmptyStateCard: View {
    let title: String
    let systemImage: String

    var body: some View {
        InfoCard {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

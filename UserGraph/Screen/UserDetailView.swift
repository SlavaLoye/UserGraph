//
//  UserDetailView.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI

struct UserDetailView: View {
    let user: User

    @State private var isShowingFullImage = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                InfoCard {
                    VStack(spacing: 16) {
                        AvatarView(url: avatarURL)
                            .frame(width: 140, height: 140)
                            .shadow(color: Theme.cardShadow(for: scheme).opacity(0.55), radius: 16, x: 0, y: 10)
                            .onTapGesture {
                                if avatarURL != nil {
                                    isShowingFullImage = true
                                }
                            }

                        // Имя — белый текст
                        Text(user.username)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        // Характеристики — белый/полубелый
                        HStack(spacing: 12) {
                            Label("\(user.age)", systemImage: "figure.and.child.holdinghands")
                            Text("•").foregroundStyle(.white.opacity(0.6))
                            Label(user.sex, systemImage: "person")
                            if user.isOnline {
                                Text("•").foregroundStyle(.white.opacity(0.6))
                                Label("online", systemImage: "circle.fill")
                                    .labelStyle(.titleAndIcon)
                                    .foregroundStyle(Color.green)
                            }
                        }
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 6)
                }

                if !nonAvatarFiles.isEmpty {
                    InfoCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Файлы")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)

                            ForEach(nonAvatarFiles, id: \.id) { file in
                                HStack(spacing: 12) {
                                    Image(systemName: "doc")
                                        .foregroundStyle(.white.opacity(0.7))
                                        .imageScale(.medium)

                                    // Имя файла — белый
                                    Text(file.url.lastPathComponent)
                                        .font(.body)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .truncationMode(.middle)

                                    Spacer()

                                    // Тип файла — белый в бейдже
                                    Text(file.type.uppercased())
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.12))
                                                .overlay(
                                                    Capsule().stroke(Theme.glassStroke(for: scheme), lineWidth: 1)
                                                )
                                        )
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(
            Theme.backgroundGradient(for: scheme)
                .ignoresSafeArea()
        )
        .toolbarBackground(.hidden, for: .navigationBar) // убираем фон, чтобы титул был читабельным на градиенте
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Профиль")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white) // титл — белый
            }
        }
        .fullScreenCover(isPresented: $isShowingFullImage) {
            FullscreenImageView(url: avatarURL) {
                isShowingFullImage = false
            }
        }
    }

    private var avatarURL: URL? {
        user.files.first(where: { $0.type == "avatar" })?.url
    }

    private var nonAvatarFiles: [UserFile] {
        user.files.filter { $0.type.lowercased() != "avatar" }
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

// Полноэкранные компоненты
private struct FullscreenImageView: View {
    let url: URL?
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    // Simple pinch-to-zoom state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            // Background
            Theme.backgroundGradient(for: scheme)
                .ignoresSafeArea()

            Group {
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height)
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        },
                    MagnificationGesture()
                        .onChanged { value in
                            scale = max(1.0, lastScale * value)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: scale)
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: offset)

            // Top bar with close button — белый текст
            VStack {
                HStack {
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Закрыть")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.35))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)

                    Spacer()
                }
                Spacer()
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.clear
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.8))
                .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

//
//  OwnerSetupView.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct OwnerSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let email: String

    @State private var username: String = ""
    @State private var sex: String = "male"
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    @State private var selectedItem: PhotosPickerItem?
    @State private var avatarImageData: Data?
    @State private var isSaving = false
    @State private var error: String?

    @FocusState private var focusedField: Field?
    private enum Field { case username }

    private let sexes = ["male", "female", "other"]

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Тёмный градиентный фон
                Theme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                // Декоративные световые пятна
                ZStack {
                    Circle()
                        .fill(Theme.glow1)
                        .blur(radius: 120)
                        .frame(width: 320, height: 320)
                        .offset(x: -160, y: -420)

                    Circle()
                        .fill(Theme.glow2)
                        .blur(radius: 140)
                        .frame(width: 340, height: 340)
                        .offset(x: 180, y: 520)
                }
                .allowsHitTesting(false)

                ScrollView {
                    VStack(spacing: 22) {
                        // Аватар + кнопка выбора
                        GlassCard {
                            VStack(spacing: 14) {
                                avatarPreview
                                    .frame(width: 140, height: 140)
                                    .shadow(color: Theme.cardShadow(for: scheme).opacity(0.55), radius: 16, x: 0, y: 10)

                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                        Text("Выбрать фото")
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.08))
                                            .overlay(
                                                Capsule().stroke(Theme.fieldStroke, lineWidth: 1)
                                            )
                                    )
                                    .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // Форма
                        GlassCard {
                            VStack(spacing: 16) {
                                // Имя
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Имя")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.8))
                                    HStack(spacing: 10) {
                                        Image(systemName: "person")
                                            .foregroundStyle(.white.opacity(0.6))
                                        TextField("Ваше имя", text: $username)
                                            .focused($focusedField, equals: .username)
                                            .foregroundStyle(.white)
                                    }
                                    .padding(14)
                                    .background(fieldBackground)
                                }

                                // Пол
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Пол")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.8))
                                    HStack {
                                        Image(systemName: "figure.arms.open")
                                            .foregroundStyle(.white.opacity(0.6))
                                        Spacer().frame(width: 4)
                                        Picker("", selection: $sex) {
                                            ForEach(sexes, id: \.self) { s in
                                                Text(s.capitalized).tag(s)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .tint(Theme.accent)
                                    }
                                    .padding(10)
                                    .background(fieldBackground)
                                }

                                // Дата рождения
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Дата рождения")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.8))
                                    HStack(spacing: 10) {
                                        Image(systemName: "calendar")
                                            .foregroundStyle(.white.opacity(0.6))
                                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                                            .labelsHidden()
                                            .tint(Theme.accent)
                                            .foregroundStyle(.white)
                                    }
                                    .padding(12)
                                    .background(fieldBackground)
                                }

                                if let error {
                                    Text(error)
                                        .font(.footnote)
                                        .foregroundStyle(.red.opacity(0.9))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }

                        // Кнопка Сохранить
                        Button(action: save) {
                            HStack(spacing: 10) {
                                if isSaving { ProgressView().tint(.black.opacity(0.9)) }
                                Image(systemName: "checkmark.seal.fill")
                                Text("Сохранить")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .foregroundStyle(.black.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Theme.primaryButtonGradient()
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            )
                            .shadow(color: Theme.primaryButtonShadow, radius: 18, x: 0, y: 12)
                        }
                        .disabled(isSaving)
                        .opacity(isSaving ? 0.8 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Ваш профиль")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        resignKeyboard()
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить", action: save)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .onAppear {
            preloadOwnerIfExists()
            print("OwnerSetupView.onAppear email=\(email)")
        }
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadImageData(from: newItem) }
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Theme.fieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.fieldStroke, lineWidth: 1)
            )
    }

    private var avatarPreview: some View {
        Group {
            if let data = avatarImageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.avatarStroke, lineWidth: 1))
            } else {
                AvatarView(url: nil)
            }
        }
    }

    private func preloadOwnerIfExists() {
        let e = email
        let descriptor = FetchDescriptor<Owner>(predicate: #Predicate<Owner> { $0.email == e })
        if let existing = try? modelContext.fetch(descriptor).first {
            username = existing.username
            sex = existing.sex.isEmpty ? sex : existing.sex
            birthDate = existing.birthDate

            // Попробуем прочитать данные по сохранённому URL
            var loadedData: Data? = nil
            if let url = existing.avatarURL, FileManager.default.fileExists(atPath: url.path) {
                loadedData = try? Data(contentsOf: url)
            }

            // Если по сохранённому абсолютному URL файл не найден (часто после перебилда),
            // попробуем восстановить новый путь в текущем контейнере (Application Support/Owner/owner_avatar.jpg)
            if loadedData == nil {
                if let recoveredURL = try? currentOwnerAvatarURLInThisInstall(),
                   FileManager.default.fileExists(atPath: recoveredURL.path) {
                    loadedData = try? Data(contentsOf: recoveredURL)

                    // Если удалось восстановить — обновим ссылку в модели и сохраним
                    if loadedData != nil {
                        existing.avatarURL = recoveredURL
                        try? modelContext.save()
                        #if DEBUG
                        print("OwnerSetupView.preload: recovered avatarURL to \(recoveredURL.path)")
                        #endif
                    }
                }
            }

            avatarImageData = loadedData
            print("OwnerSetupView.preload: found existing owner for \(e)")
        } else {
            print("OwnerSetupView.preload: no owner for \(e)")
        }
    }

    // Возвращает ожидаемый путь к аватару владельца в текущей установке приложения
    private func currentOwnerAvatarURLInThisInstall() throws -> URL {
        let fm = FileManager.default
        let appSupportDir = try fm.url(for: .applicationSupportDirectory,
                                       in: .userDomainMask,
                                       appropriateFor: nil,
                                       create: true)
        let dir = appSupportDir.appendingPathComponent("Owner", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("owner_avatar.jpg")
    }

    private func save() {
        Task {
            guard !isSaving else { return }
            isSaving = true
            defer { isSaving = false }

            resignKeyboard()

            let minDate = Date(timeIntervalSince1970: 0)
            print("OwnerSetupView.save: incoming email=\(email), username=\(username), sex=\(sex), birthDate=\(birthDate)")
            guard !email.isEmpty, !username.isEmpty, !sex.isEmpty, birthDate > minDate else {
                self.error = "Заполните все поля"
                print("OwnerSetupView.save: validation failed")
                return
            }

            do {
                let avatarURL = try await persistAvatarIfNeeded()

                let e = email
                let descriptor = FetchDescriptor<Owner>(predicate: #Predicate<Owner> { $0.email == e })
                let owners = try modelContext.fetch(descriptor)
                if let existing = owners.first {
                    existing.username = username
                    existing.sex = sex
                    existing.birthDate = birthDate
                    existing.avatarURL = avatarURL
                    existing.updatedAt = Date()
                    print("OwnerSetupView.save: updated existing owner")
                } else {
                    let new = Owner(email: e,
                                    username: username,
                                    sex: sex,
                                    birthDate: birthDate,
                                    avatarURL: avatarURL)
                    modelContext.insert(new)
                    print("OwnerSetupView.save: inserted new owner")
                }
                try modelContext.save()

                let verify = try modelContext.fetch(FetchDescriptor<Owner>(predicate: #Predicate { $0.email == e }))
                if let v = verify.first {
                    print("OwnerSetupView.verify: saved owner isFilled=\(v.isFilled), username=\(v.username), sex=\(v.sex), birthDate=\(v.birthDate), avatarURL=\(String(describing: v.avatarURL))")
                } else {
                    print("OwnerSetupView.verify: owner not found after save for email=\(e)")
                }

                NotificationCenter.default.post(name: .ownerDidChange, object: nil)

                dismiss()
            } catch {
                self.error = "Не удалось сохранить профиль"
                print("OwnerSetupView.save: error \(error)")
            }
        }
    }

    private func loadImageData(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await MainActor.run { avatarImageData = data }
            }
        } catch {
            await MainActor.run { self.error = "Ошибка выбора изображения" }
        }
    }

    private func persistAvatarIfNeeded() async throws -> URL? {
        guard let data = avatarImageData else { return nil }
        let fm = FileManager.default

        // Use Application Support instead of Caches for persistence across app restarts/builds
        let appSupportDir = try fm.url(for: .applicationSupportDirectory,
                                       in: .userDomainMask,
                                       appropriateFor: nil,
                                       create: true)

        // Create app-specific subfolder (optional but tidy)
        let dir = appSupportDir.appendingPathComponent("Owner", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        let fileURL = dir.appendingPathComponent("owner_avatar.jpg")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func resignKeyboard() {
        focusedField = nil
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
        #endif
    }
}

// Универсальная стеклянная карточка (совместима со стилем Login/Profile/Detail)
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
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.02))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Theme.glassStroke(for: scheme), lineWidth: 1)
                    )
            )
            .shadow(color: Theme.cardShadow(for: scheme), radius: 22, x: 0, y: 14)
    }
}

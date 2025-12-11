//
//  LoginView.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - View
struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [Session]

    // Локальное состояние без VM
    @State private var email: String = ""
    @State private var error: String?

    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var scheme

    init() {
        print("LoginView.init")
        _sessions = Query(sort: \Session.createdAt, order: .forward, animation: .default)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                ZStack {
                    Circle()
                        .fill(Theme.glow1)
                        .blur(radius: 90)
                        .frame(width: 260, height: 260)
                        .offset(x: -140, y: -280)

                    Circle()
                        .fill(Theme.glow2)
                        .blur(radius: 110)
                        .frame(width: 280, height: 280)
                        .offset(x: 160, y: 300)
                }
                .allowsHitTesting(false)

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 6) {
                            Text("Добро пожаловать")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Войдите по email, чтобы продолжить")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24)

                        GlassCard {
                            VStack(spacing: 14) {
                                HStack {
                                    Label("Email", systemImage: "envelope.fill")
                                        .labelStyle(.titleAndIcon)
                                        .foregroundStyle(.white.opacity(0.9))
                                        .font(.headline)
                                    Spacer()
                                }

                                HStack(spacing: 10) {
                                    Image(systemName: "envelope")
                                        .foregroundStyle(.white.opacity(0.6))
                                    TextField("name@example.com", text: $email)
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                        .textContentType(.emailAddress)
                                        .autocorrectionDisabled()
                                        .focused($focused)
                                        .foregroundStyle(.white)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Theme.fieldBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(Theme.fieldStroke, lineWidth: 1)
                                        )
                                )

                                if let error {
                                    Text(error)
                                        .font(.footnote)
                                        .foregroundStyle(.red.opacity(0.9))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                Button(action: {
                                    print("LoginView: Login button tapped")
                                    login()
                                    dumpSessions(context: "after Login button")
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "arrow.right.circle.fill")
                                        Text("Войти")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.headline)
                                    .foregroundStyle(.black.opacity(0.9))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        Theme.primaryButtonGradient()
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    )
                                    .shadow(color: Theme.primaryButtonShadow, radius: 16, x: 0, y: 10)
                                }
                                .disabled(!isEmailValid(email))
                                .opacity(isEmailValid(email) ? 1 : 0.6)
                            }
                        }

                        Text("Продолжая, вы соглашаетесь с условиями использования и политикой конфиденциальности.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                // Снижаем конфликты с клавиатурой
                .scrollDismissesKeyboard(.interactively)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationBarHidden(true)
            .onTapGesture { focused = false }
        }
        .onAppear {
            print("LoginView.onAppear start. @Query sessions.count=\(sessions.count)")
            // Подхватим email из существующей сессии (если есть непустой)
            if let s = sessions.first, !s.email.isEmpty {
                email = s.email
                print("LoginView.onAppear: prefill email from session -> \(email)")
            }
            dumpSessions(context: "after onAppear")
        }
        .onChange(of: sessions) { _, newValue in
            print("LoginView.onChange sessions -> count=\(newValue.count)")
            if let first = newValue.first {
                print("  first email=\(first.email) loggedIn=\(first.isLoggedIn) createdAt=\(first.createdAt)")
            }
        }
    }

    private func login() {
        print("LoginView.login tapped with email='\(email)'")
        guard isEmailValid(email) else {
            error = "Введите корректный email"
            print("LoginView.login invalid email")
            return
        }
        error = nil
        do {
            var stored = try modelContext.fetch(FetchDescriptor<Session>())
            if let existing = stored.first {
                print("LoginView.login: updating existing session")
                existing.email = email
                existing.isLoggedIn = true
            } else {
                print("LoginView.login: creating new session")
                let s = Session(email: email, isLoggedIn: true)
                modelContext.insert(s)
            }
            try modelContext.save()
            print("LoginView.login: modelContext.save() success")
            // Дальше навигацией управляет ContentView (покажет OwnerSetupView или MainTabView)
        } catch {
            self.error = "Не удалось сохранить сессию"
            print("LoginView.login: error -> \(error)")
        }
    }

    private func isEmailValid(_ e: String) -> Bool {
        let regex = #/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/#
        let ok = e.wholeMatch(of: regex) != nil
        print("LoginView.isEmailValid('\(e)') -> \(ok)")
        return ok
    }

    private func dumpSessions(context: String) {
        let descriptor = FetchDescriptor<Session>()
        let fetched = try? modelContext.fetch(descriptor)
        print("LoginView.dumpSessions (\(context)): @Query.count=\(sessions.count) fetched.count=\(fetched?.count ?? -1)")
        if let fetched {
            for (i, s) in fetched.enumerated() {
                print("  fetched[\(i)] email=\(s.email) loggedIn=\(s.isLoggedIn) createdAt=\(s.createdAt)")
            }
        }
        if let first = sessions.first {
            print("  @Query.first email=\(first.email) loggedIn=\(first.isLoggedIn)")
        } else {
            print("  @Query.first is nil")
        }
    }
}

// Универсальная «стеклянная» 3D-карточка для тёмной темы
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

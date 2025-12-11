//
//  ContentView.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    // Сессия
    @Query(sort: \Session.createdAt, order: .forward, animation: .default)
    private var sessions: [Session]

    // Текущий email из сессии, чтобы использовать его в предикате для Owner
    @State private var currentEmail: String = ""

    // Владелец, реактивно по текущему email
    @Query private var owners: [Owner]

    // Локальная необходимость сетапа, вычисляется от owners.first?.isFilled
    @State private var needsOwnerSetup = false

    @Environment(\.colorScheme) private var scheme

    init() {
        _owners = Query()
    }

    init(currentEmail: String = "") {
        _sessions = Query(sort: \Session.createdAt, order: .forward, animation: .default)
        _owners = currentEmail.isEmpty
        ? Query()
        : Query(
            filter: #Predicate<Owner> { $0.email == currentEmail },
            sort: \.createdAt,
            order: .forward,
            animation: .default
        )
    }

    var body: some View {
        ZStack {
            // Общий фон приложения
            Theme.backgroundGradient(for: scheme)
                .ignoresSafeArea()

            // Декоративные «световые пятна»
            ZStack {
                Circle()
                    .fill(Theme.glow1)
                    .blur(radius: 120)
                    .frame(width: 360, height: 360)
                    .offset(x: -160, y: -420)

                Circle()
                    .fill(Theme.glow2)
                    .blur(radius: 140)
                    .frame(width: 360, height: 360)
                    .offset(x: 180, y: 520)
            }
            .allowsHitTesting(false)

            Group {
                if sessions.first?.isLoggedIn == true {
                    if needsOwnerSetup {
                        if !currentEmail.isEmpty {
                            NavigationStack {
                                OwnerSetupView(email: currentEmail)
                                    .navigationTitle("Ваш профиль")
                                    .navigationBarTitleDisplayMode(.large)
                            }
                            .transition(.opacity.combined(with: .scale))
                        } else {
                            LoginView()
                                .transition(.opacity)
                        }
                    } else {
                        MainTabView()
                            .transition(.opacity)
                    }
                } else {
                    LoginView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: sessions.first?.isLoggedIn ?? false)
            .animation(.easeInOut(duration: 0.25), value: needsOwnerSetup)
            .animation(.easeInOut(duration: 0.25), value: currentEmail)
        }
        .onAppear {
            ensureSingleSession()
            syncCurrentEmailFromSession()
            recomputeNeedsOwnerSetup()
        }
        .onChange(of: sessions.first?.isLoggedIn ?? false) { old, new in
            print("ContentView: isLoggedIn changed \(old) -> \(new)")
            syncCurrentEmailFromSession()
            recomputeNeedsOwnerSetup()
        }
        .onChange(of: sessions.first?.email ?? "") { old, new in
            print("ContentView: email changed \(old) -> \(new)")
            syncCurrentEmailFromSession()
            recomputeNeedsOwnerSetup()
        }
        .onChange(of: owners.map(\.updatedAt)) { _, _ in
            recomputeNeedsOwnerSetup()
        }
        .onChange(of: owners.count) { _, _ in
            recomputeNeedsOwnerSetup()
        }
    }

    private func ensureSingleSession() {
        if sessions.isEmpty {
            let new = Session(email: "", isLoggedIn: false)
            modelContext.insert(new)
            try? modelContext.save()
            print("ContentView.ensureSingleSession: created empty session")
            return
        }

        if sessions.count > 1 {
            let sorted = sessions.sorted(by: { $0.createdAt < $1.createdAt })
            guard let keep = sorted.first else { return }
            for s in sorted.dropFirst() {
                modelContext.delete(s)
            }
            try? modelContext.save()
            print("ContentView.ensureSingleSession: reduced sessions to single id=\(keep.id)")
        }
    }

    private func syncCurrentEmailFromSession() {
        let newEmail = sessions.first?.email ?? ""
        if currentEmail != newEmail {
            print("ContentView: currentEmail \(currentEmail) -> \(newEmail)")
            currentEmail = newEmail
        }
    }

    private func recomputeNeedsOwnerSetup() {
        guard let s = sessions.first, s.isLoggedIn else {
            needsOwnerSetup = false
            print("recomputeNeedsOwnerSetup: not logged in")
            return
        }
        let ownerForEmail: Owner? = {
            guard !currentEmail.isEmpty else { return nil }
            let descriptor = FetchDescriptor<Owner>(predicate: #Predicate<Owner> { $0.email == currentEmail },
                                                    sortBy: [SortDescriptor(\.createdAt, order: .forward)])
            return (try? modelContext.fetch(descriptor).first) ?? owners.first
        }()

        let filled = ownerForEmail?.isFilled ?? false
        needsOwnerSetup = !filled
        print("recomputeNeedsOwnerSetup: email=\(currentEmail), ownerExists=\(ownerForEmail != nil), isFilled=\(filled)")
        if let o = ownerForEmail {
            print("recomputeNeedsOwnerSetup: owner.username=\(o.username), sex=\(o.sex), birthDate=\(o.birthDate)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Session.self, User.self, UserFile.self, Owner.self], inMemory: true)
}

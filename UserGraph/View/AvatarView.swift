//
//  AvatarView.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI
import Combine

private final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        // Настроим разумные лимиты (можно подогнать)
        cache.countLimit = 300
        cache.totalCostLimit = 50 * 1024 * 1024 // ~50 MB
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        let cost = image.jpegData(compressionQuality: 0.7)?.count ?? 1
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

@MainActor
private final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false

    private var currentTask: Task<Void, Never>?

    func load(from url: URL?) {
        // Если URL отсутствует — сброс и выход
        guard let url else {
            image = nil
            isLoading = false
            currentTask?.cancel()
            currentTask = nil
            return
        }

        // Если уже есть в кэше — моментально отдадим
        if let cached = ImageCache.shared.image(for: url) {
            image = cached
            isLoading = false
            return
        }

        // Отменим предыдущую задачу, если была
        currentTask?.cancel()

        isLoading = true
        image = nil

        currentTask = Task { [weak self] in
            guard let self else { return }
            // До 3 попыток с небольшим бэкоффом
            let attempts = 3
            var lastError: Error?

            for attempt in 0..<attempts {
                if Task.isCancelled { return }

                do {
                    let req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
                    let (data, response) = try await URLSession.shared.data(for: req)

                    // Проверка ответа
                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        throw URLError(.badServerResponse)
                    }

                    if Task.isCancelled { return }

                    if let img = UIImage(data: data) {
                        ImageCache.shared.insert(img, for: url)
                        if Task.isCancelled { return }
                        self.image = img
                        self.isLoading = false
                        return
                    } else {
                        throw URLError(.cannotDecodeContentData)
                    }
                } catch {
                    lastError = error
                    // Небольшая задержка перед повтором, кроме последней попытки
                    if attempt < attempts - 1 {
                        try? await Task.sleep(nanoseconds: UInt64(300_000_000) * UInt64(attempt + 1)) // 0.3s, 0.6s
                    }
                }
            }

            // Если не удалось — просто покажем плейсхолдер
            if Task.isCancelled { return }
            self.isLoading = false
            // image остаётся nil -> покажется placeholder
            #if DEBUG
            if let lastError {
                print("ImageLoader: failed to load \(url.absoluteString): \(lastError)")
            }
            #endif
        }
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
}

struct AvatarView: View {
    let url: URL?

    @StateObject private var loader = ImageLoader()

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity.combined(with: .scale))
            } else if loader.isLoading {
                ProgressView()
                    .tint(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder
            }
        }
        .onAppear {
            loader.load(from: url)
        }
        .onChange(of: url) { _, newValue in
            loader.load(from: newValue)
        }
        .onDisappear {
            // Не очищаем кэш, но отменяем активную загрузку
            loader.cancel()
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(Theme.avatarStroke, lineWidth: 1))
        .background(
            Circle().fill(Color(.secondarySystemBackground))
        )
    }

    private var placeholder: some View {
        ZStack {
            Color.clear
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .padding(8)
        }
    }
}


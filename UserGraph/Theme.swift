//
//  Theme.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI

enum Theme {
    // Акцентный цвет (можно быстро поменять на любой: .blue, .pink, кастомный)
    static let accent = Color.orange

    // Вторичный акцент (для градиентов кнопок)
    static let accentSecondary = Color.orange.opacity(0.85)

    // Тёмный фон приложения (градиент) — как в референсе
    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.black.opacity(0.96),
                Color(hue: 0.08, saturation: 0.12, brightness: scheme == .dark ? 0.18 : 0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Декоративные «световые пятна» (фоновые)
    static let glow1 = Color.orange.opacity(0.18)
    static let glow2 = Color.orange.opacity(0.14)

    // Стеклянный фон карточек (ultra-thin стиль, но управляемый)
    static func glassFill() -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.08),
                Color.white.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Обводка стеклянных карточек
    static func glassStroke(for scheme: ColorScheme) -> Color {
        Color.white.opacity(scheme == .dark ? 0.12 : 0.18)
    }

    // Тень карточек
    static func cardShadow(for scheme: ColorScheme) -> Color {
        Color.black.opacity(scheme == .dark ? 0.35 : 0.18)
    }

    // Фон для полей ввода/контролов
    static let fieldBackground = Color.white.opacity(0.06)
    static let fieldStroke = Color.white.opacity(0.12)

    // Градиент для «позитивных» кнопок
    static func primaryButtonGradient() -> LinearGradient {
        LinearGradient(
            colors: [accent, accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Тень для «позитивных» кнопок
    static let primaryButtonShadow = Color.orange.opacity(0.45)

    // Деструктивные кнопки
    static func destructiveButtonGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color.red, Color.red.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    static let destructiveButtonShadow = Color.red.opacity(0.35)

    // Обводка круглых аватаров
    static let avatarStroke = Color.white.opacity(0.18)
}

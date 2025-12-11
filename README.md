
<img width="300" height="600" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-11 at 16 55 23" src="https://github.com/user-attachments/assets/f56727bc-cfae-4460-8b6c-42e07970d08d" />

<img width="300" height="600" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-11 at 16 56 10" src="https://github.com/user-attachments/assets/632a7e0a-621f-4045-be02-7b668549d127" />


<img width="300" height="600" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-11 at 16 55 28" src="https://github.com/user-attachments/assets/d45d628f-2e92-4e9d-a152-8f0cbd4c5e15" />


<img width="300" height="600" alt="Simulator Screenshot - iPhone 17 Pro - 2025-12-11 at 16 55 31" src="https://github.com/user-attachments/assets/35662921-4327-4b5a-9965-080a21cb11ec" />


UserGraph

Интерактивное iOS‑приложение на SwiftUI с локальным хранилищем (SwiftData), в котором:

• пользователь авторизуется по email,

• заполняет свой профиль владельца (Owner) с аватаром,

• просматривает список пользователей из API,

• открывает карточки пользователей,

• видит таб «Статистика» (плейсхолдер) — готов к подключению к реальным данным.

Основные фичи

• Вход по email

   • Простая форма логина с валидацией email.
   
   • Состояние входа хранится локально в SwiftData (Session).
   
   • При повторном запуске приложение подхватывает активную сессию.

• Настройка профиля владельца (Owner)

   • Экран OwnerSetupView появляется автоматически после входа, если профиль ещё не заполнен.
   
   • Имя, пол, дата рождения, выбор аватара из библиотеки (PhotosPicker).
   
   • Аватар сохраняется в кэш и ссылка хранится в SwiftData.

• Профиль

   • Стеклянная карточка с крупным аватаром, именем и метаданными.
   
   • Быстрый переход к редактированию профиля.
   
   • Кнопка «Выйти» очищает состояние входа.

• Список пользователей

   • Загрузка пользователей из публичного API (http://test-case.rikmasters.ru/api/episode/users/).
   
   • Кэширование в SwiftData (модели User и UserFile).
   
   • Детальная карточка пользователя с файлами (avatar/другие).

• Статистика (плейсхолдер)

   • Экран готов для подключения реальных метрик.
   
   • Сейчас — аккуратные стеклянные карточки и «скелетон» графика.

Технологии
• SwiftUI: всё UI и навигация (NavigationStack, TabView, ScrollView)

• SwiftData: локальное хранилище (Session, Owner, User, UserFile)

• Concurrency: async/await для загрузки данных

• PhotosUI: выбор аватара из фотоальбома

• Темизация

   • Единый модуль Theme (градиенты, стеклянные карточки, тени, акцентные цвета)
   
   • Аватары, кнопки, карточки выдержаны в едином стиле

Архитектура и навигация

• Точка входа: UserGraphApp

   • Конфигурирует общий ModelContainer для SwiftData и пробрасывает его в сцену.
   
• Корневой роутер: ContentView

   • Наблюдает Session и Owner и решает, что показывать:
   
      • Если не залогинен → LoginView
      
      • Если залогинен и профиль не заполнен → OwnerSetupView(email:)
      
      • Если залогинен и профиль заполнен → MainTabView
      
• Экран профиля: ProfileView

   • Отображает Owner (по email из Session), редактирование и выход
   
• Экран пользователей: UsersView

   • Грузит из API, сохраняет в SwiftData, показывает список и детали
   
• Экран настройки профиля: OwnerSetupView

   • Запрос имени, пола, даты рождения, аватара; сохранение в SwiftData

Модели SwiftData

• Session

   • email: String
   
   • isLoggedIn: Bool
   
   • createdAt: Date
   
• Owner

   • email: String (синхронизация с Session.email)
   
   • username: String
   
   • sex: String
   
   • birthDate: Date
   
   • avatarURL: URL?
   
   • createdAt, updatedAt: Date
   
   • isFilled: Bool — критерий заполненности профиля
   
• User

   • id, username, sex, age, isOnline
   
   • files: [UserFile] (отношение)
   
• UserFile

   • id, url, type

Сценарий работы

1. Первый запуск
   
• Приложение создаёт пустую Session, показывается LoginView.

3. Ввод email → Войти
   
• Email валидируется. Сессия сохраняется в SwiftData (email + isLoggedIn = true).

• ContentView реагирует и решает, что делать дальше.

5. Если Owner не заполнен → OwnerSetupView
   
• Пользователь заполняет имя/пол/дату, выбирает аватар.

• Данные сохраняются в SwiftData. Возврат в основной интерфейс.

7. Основной интерфейс (MainTabView)
   
• Вкладки: Статистика (плейсхолдер), Юзеры (список из API), Профиль.

9. Профиль

    
• Просмотр данных владельца, редактирование, выход.

Запуск проекта

• Требования

   • Xcode 15+
   
   • iOS 17+ (симулятор или устройство)
   
• Шаги

   • Откройте UserGraph.xcodeproj в Xcode
   
   • Сборка и запуск на симуляторе iPhone 15/17 (или другом)
   
   • При первом запуске увидите форму логина

Примечания по данным и приватности

• Данные профиля и сессии хранятся только локально (SwiftData/SQLite в контейнере приложения).

• Аватар сохраняется в кэше (FileManager.cachesDirectory) — ссылка хранится в Owner.avatarURL.

• Пользователи для вкладки «Юзеры» загружаются из публичного API (только чтение).

Что можно улучшить (дорожная карта)

• Авторизация по коду/ссылке (email link/OTP)

• MVVM - вынести бизнес логику

• Хранение токена и защищённое хранилище (Keychain)

• Настоящая статистика и графики (Charts)

• Поддержка темизации (светлая/тёмная) и кастомных тем

• Локализация (RU/EN)

• Кэш изображений и офлайн‑режим

• Юнит‑тесты и снапшот‑тесты UI (Swift Testing/XCTest)

Структура проекта (укрупнённо)

• App: UserGraphApp.swift — конфиг SwiftData

• Root: ContentView.swift — маршрутизация между состояниями

• Auth: LoginView.swift — форма входа

• Owner: Owner.swift, OwnerSetupView.swift — профиль владельца

• Users: UsersView.swift, UserDetailView.swift , APIClient.swift  — список и детали пользователей

• Profile: ProfileView.swift — профиль и действия (редактировать/выйти)

• Theme/UI: Theme.swift, AvatarView.swift — визуальные компоненты

• Models: Session.swift, User.swift, UserFile.swift — SwiftData модели

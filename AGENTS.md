# Agentic Development Guide - Vision Proj (tvOS)

Welcome, Agent. This document provides critical architectural context, standard rules, hotspots, and our suggested improvement roadmap for working on the Vision project—a high-performance tvOS media application built with native UIKit, Combine, Swift Concurrency, and Clean Architecture principles.

---

## 🛠 Technology Stack

- **Platform**: tvOS 17.0+
- **Architecture**: Clean Architecture + MVVM + Coordinator (with a dedicated Dependency Injection Container).
- **UI Framework**: Native UIKit (Auto Layout, UICollectionView Compositional Layout, custom focus controls).
- **Reactive Framework**: Combine (exclusively for UI-state bindings, reactive theming, and settings updates).
- **Networking**: Swift Concurrency (`async`/`await`) + Alamofire wrapper.
- **Focus Engine**: Standard tvOS Focus Engine integrated via customized interactive controls.

---

## 📁 Project Architecture & Dependency Flow

Our project strictly adheres to **Clean Architecture** principles. The core rule of Clean Architecture is that **dependencies flow inwards towards the Domain layer**. The Domain layer is the architectural center: it owns business entities, repository protocols, and use cases, and it contains no dependencies on external libraries or outer layers (UI, network, storage).

> **Note on Domain Purity**: The Domain layer is fully isolated from external UI or system frameworks. All previous legacy imports of `UIKit` in the Domain layer have been fully cleaned up.

### 📦 Project File Map

1. **`Vision/Domain` (The Independent Core)**
   - **`Entity`**: Pure domain models and structs (e.g., `ContentItem`, `Translation`, `PlaybackContext`, `PlaybackState`, `Theme`, `AppLanguage`, `Category`, `Genre`, `SettingsData`, `SettingsStorageData`). Contains zero framework imports and represents the pure business state.
   - **`Repository`**: Swift protocol interfaces defining data access patterns (e.g., `FavoritesRepository`, `PlaybackStateRepository`, `WatchHistoryRepository`, `SettingsRepositoryProtocol`, `ImageRepositoryProtocol`).
   - **`UseCase`**: Encapsulates business logic and coordinates data flow (e.g., `PlayerUseCase`, `FavoritesUseCase`, `WatchHistoryUseCase`, `GetContentUseCase`, `GetMovieDetailUseCase`, `SearchUseCase`, `SettingsUseCase`). They interact only with domain entities and repository protocols.

2. **`Vision/Data` (The Gatekeeper of Data)**
   - **`Repository`**: Concrete implementations of Domain repository protocols mapping persistence objects to Domain entities (e.g., `CoreDataFavoritesRepository`, `CoreDataPlaybackStateRepository`, `CoreDataWatchHistoryRepository`).
   - **`Service`**: Framework adapters implementing Domain services, e.g., `SettingsService` implementing `SettingsRepositoryProtocol`.
   - *Note on Networking*: Low-level API communication is offloaded to the external `Filmix` framework package. It is wrapped inside `Vision/Infrastructure/Filmix.swift` via the `FilmixProtocol` (acting as a gateway for movies parsing, detail retrieval, translations, and search).

3. **`Vision/Presentation` (The Interface)**
   - **`Screens`**: Grouped folders containing ViewControllers and state-driven ViewModels:
     - `App`: The root container VC and VM (`AppController.swift`, `AppViewModel.swift`) orchestrating the custom top tab bar and workspace swapping.
     - `Movies`: Holds `MoviesController` and its collection of data source view models (`MoviesViewModel`, `FavoritesViewModel`, `WatchHistoryViewModel`) conforming to the shared `ContentListViewModelProtocol`.
     - `Detail`: Movie and Series details (`MovieDetailViewController/ViewModel`, `SerieDetailViewController/ViewModel`) sharing `BaseDetailViewController.swift`.
     - `Search`: Simple query/filter controller (`SearchViewController`, `SearchViewModel`).
     - `Settings`: Setup interface (`SettingsViewController`, `SettingsViewModel`).
     - `Video`: Video engine page controller (`VideoController`, `VideoViewModel`, overlays, and controls).
   - **`Components`**: Small, reusable layout components separated by context:
     - `Detail/`: Row views, season selectors, and labels (`EpisodeRow.swift`, `SeasonTabButton.swift`, `TranslationRow.swift`, etc.).
     - `Settings/`: Option items and settings sliders (`SettingsValueRow.swift`, `SettingsSliderRow.swift`, `SettingsStorageSectionView.swift`, etc.).

4. **`Vision/Infrastructure` (Cross-Cutting Concerns)**
   - **`BaseController.swift`**: The base view controller that handles theme updates and styling hooks for all screens.
   - **Global Helpers**: Shared managers such as `ThemeManager.swift`, `LanguageManager.swift`, `FontSettingsManager.swift`, and image loaders like `PosterCache.swift` (implementing `ImageRepositoryProtocol`).
   - **Utility Controls**: UI components like `TVFocusControl.swift`, `ModalController.swift`, `PickerViewController.swift`.
   - **`Player/`**: Custom AVPlayer wrapper engine and view (`QueueVideoPlayerEngine.swift`, `QueueVideoPlayerLayerView.swift`).
   - **`Persistence/`**: DB synchronization (`CoreDataStack.swift`), UserDefaults adapters (`PlaybackProgressManager.swift`, `FavoritesManager.swift`, `WatchHistoryManager.swift`), and the `Entities/` folder hosting DB managed structures (`CDFavorite`, `CDHistory`, `CDPlaybackState`, `CDEpisodeProgress`).
   - **`TabBar/`**: Reusable custom tab bar implementation (`TabBarView.swift`, `TabBarButton.swift`).
   - **`UIKit/`**: Pure extensions and styling assets (`ThemeStyle.swift`, `Color.swift`, `Font.swift`).

5. **`Vision/App` (The Composition Root)**
   - Wires up the lifecycle (`AppDelegate`), Dependency Injection container (`Container.swift`), views assembly Factory (`Factory.swift`), and navigation controller (`Coordinator.swift`).

### 🔁 Typical Feature Flow

For most features, start from the screen and follow this chain:

`Presentation/Screens/...ViewController` -> `Presentation/Screens/...ViewModel` -> `Domain/UseCase/...UseCase` -> `Domain/Repository/...Protocol` -> `Data/Repository/...Repository`

Framework-heavy helpers live outside that chain:

- `Infrastructure/Player`: AVPlayer engine and player-layer adapters.
- `Infrastructure/Persistence`: CoreData stack, managed objects, and local persistence managers.
- `Infrastructure/UIKit`: UIKit helpers and shared view utilities.
- `Infrastructure/TabBar`: shared tab bar UI controls.
- `Resources`: assets, fonts, localization, and CoreData model files.

---

## 🧱 Clean Architecture Dependency Rules

Use these rules as the first decision filter before adding a file, import, dependency, or method:

| Layer | May depend on | Must not depend on |
|---|---|---|
| `Domain` | `Foundation` and pure Swift types only | `UIKit`, `CoreData`, `Alamofire`, `SwiftSoup`, `AVFoundation`, `Presentation`, `Data`, `Infrastructure`, `App` |
| `Data` | `Domain`, `Foundation`, network/parsing/storage implementation details | `Presentation` or UIKit view logic |
| `Infrastructure` | `Domain`, framework adapters, managers, UIKit helpers, persistence mechanics | `Presentation` screens or ViewModels |
| `Presentation` | `Domain`, UI components, view-state models, injected infrastructure protocols | concrete repositories, API clients, CoreData managed objects |
| `App` | all layers for composition only | business logic, parsing logic, persistence logic |

### Placement Rules

- **Business decision?** Put it in `Domain/UseCase`.
- **External data access?** Define the protocol in `Domain/Repository`; implement it in `Data/Repository`.
- **Framework adaptation?** Put it in `Data` or `Infrastructure`, then expose a pure Domain-facing protocol/model.
- **Screen state and user intents?** Put them in a ViewModel under `Presentation/Screens/...`.
- **UIKit rendering, focus, alerts, navigation, or collection layout?** Keep it in ViewControllers/components/coordinators, never in ViewModels or Domain.
- **New app wiring?** Add it to `App/Container` and `App/Factory`; avoid singleton lookups from feature code.

### Architecture Checklist Before Finishing a Change

1. No new forbidden imports in `Vision/Domain`.
2. ViewModels call use cases, not concrete repositories, managers, API clients, or CoreData.
3. Data repositories map DTOs/managed objects into Domain entities before returning.
4. UI-only types (`UIColor`, `UIImage`, `UIViewController`, `AVPlayer`, etc.) do not appear in new Domain APIs.
5. New user-facing strings go through `L10n.swift` and `Localizable.xcstrings`.
6. Dependencies are constructor-injected from `Container`/`Factory` rather than fetched globally.

---

## 🎨 UI & Theming Standards

- **Theming**: Always subscribe to the `ThemeManager.currentStyle` publisher. Never hardcode static colors inside views.
- **Focus Engine**: All interactive elements must inherit from or integrate with `TVFocusControl` to ensure consistent visual feedback in tvOS. Ensure hover transitions and borders have high visibility across **Dark**, **Light**, and **Midnight** themes.
- **Layout**: Use `UICollectionViewCompositionalLayout` for horizontal bands/lists and Auto Layout (anchors) for subviews. Avoid manual frame calculations.
- **Performance**: Use the custom `ImageView` component for remote images to leverage background decoding and image caching.

---

## 📝 Rules for Future Agents

1. **Maintain Clean Architecture**: Always direct dependencies inwards (**Presentation ➔ Domain** and **Data ➔ Domain**). Never import `Data`, `Presentation`, or `Infrastructure` layers into `Domain`.
2. **Domain Purity**: New Domain code must use pure Swift/Foundation models only. If a feature needs colors, images, players, CoreData objects, or UIKit styles, create an adapter in `Infrastructure`/`Presentation` instead of adding framework types to Domain.
3. **UseCase Layer**: All business rules and cross-repository flows (e.g., loading translations and checking last-saved video states) MUST reside in `Domain/UseCase`. ViewModels must never invoke repositories directly.
4. **Base Inheritance**: All ViewControllers must inherit from `BaseController` to inherit standard reactive theming, localization, and font changes.
5. **No UI side effects in VM**: ViewModels must never directly invoke UIKit operations (e.g., displaying alerts, presenting controllers). They publish state transitions, and the `ViewController` handles the visual manifestation.
6. **Localization Safety**: Hardcoded strings are forbidden. Always verify existing strings in `Vision/Infrastructure/L10n.swift` and `Vision/Resources/Localizable.xcstrings`. If a key is missing:
   - First, declare the key in `L10n.swift` under the proper nested enum.
   - Then, reference that key in the code.
7. **CoreData Boundaries**: Always perform CoreData operations on background contexts via `perform` or `performAndWait`. Map `NSManagedObject` instances to clean domain entities immediately. Do not leak managed contexts outside of `Data/Repository`.
8. **Swift 6 Concurrency**: Use `nonisolated(unsafe)` for observer-oriented callbacks (such as `onTimeUpdate` in legacy AVPlayer APIs) executing on the main queue. Prefer standard async/await for repository boundaries.

---

## 🗺 Hotspots (Read These First)

When a request relates to a specific feature domain, start with these files instead of scanning the entire project.

- **App Root & Navigation**
  - [AppController.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/App/AppController.swift)
  - [AppViewModel.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/App/AppViewModel.swift)
  - [Coordinator.swift](file:///Users/resoul/projects/Vision/Vision/App/Coordinator.swift)
  - [Container.swift](file:///Users/resoul/projects/Vision/Vision/App/Container.swift)
  - [Factory.swift](file:///Users/resoul/projects/Vision/Vision/App/Factory.swift)
- **Content Lists (Movies, Favorites, History)**
  - [MoviesController.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Movies/MoviesController.swift)
  - [MoviesViewModel.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Movies/MoviesViewModel.swift)
  - [FavoritesViewModel.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Movies/FavoritesViewModel.swift)
  - [WatchHistoryViewModel.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Movies/WatchHistoryViewModel.swift)
  - [ContentListViewModelProtocol.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Movies/ContentListViewModelProtocol.swift)
- **Player Overlay & UI Controls**
  - [VideoController.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Video/VideoController.swift)
  - [VideoPlayerOverlay.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Video/VideoPlayerOverlay.swift)
  - [VideoSliderControl.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Video/VideoSliderControl.swift)
- **Player ViewModel & Domain Logic**
  - [VideoViewModel.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Video/VideoViewModel.swift)
  - [PlayerUseCase.swift](file:///Users/resoul/projects/Vision/Vision/Domain/UseCase/PlayerUseCase.swift)
  - [QueueVideoPlayerEngine.swift](file:///Users/resoul/projects/Vision/Vision/Infrastructure/Player/QueueVideoPlayerEngine.swift)
  - [PlaybackProgressManager.swift](file:///Users/resoul/projects/Vision/Vision/Infrastructure/Persistence/PlaybackProgressManager.swift)
- **Detail Screens (Movies & Series)**
  - [BaseDetailViewController.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Detail/BaseDetailViewController.swift)
  - [MovieDetailViewController.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Detail/MovieDetailViewController.swift)
  - [MovieDetailViewModel.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Detail/MovieDetailViewModel.swift)
  - [SerieDetailViewController.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Detail/SerieDetailViewController.swift)
  - [SerieDetailViewModel.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Detail/SerieDetailViewModel.swift)
  - [EpisodeRow.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Components/Detail/EpisodeRow.swift)
  - [SeasonTabButton.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Components/Detail/SeasonTabButton.swift)
  - [TranslationRow.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Components/Detail/TranslationRow.swift)
- **Settings & API Gateway**
  - [SettingsViewController.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Settings/SettingsViewController.swift)
  - [SettingsViewModel.swift](file:///Users/resoul/projects/Vision/Vision/Presentation/Screens/Settings/SettingsViewModel.swift)
  - [SettingsUseCase.swift](file:///Users/resoul/projects/Vision/Vision/Domain/UseCase/SettingsUseCase.swift)
  - [SettingsService.swift](file:///Users/resoul/projects/Vision/Vision/Data/Service/SettingsService.swift)
  - [Filmix.swift](file:///Users/resoul/projects/Vision/Vision/Infrastructure/Filmix.swift)

---

## 👥 Feature Ownership Map

- **App & Layout Domain**:
  - *UI/Interaction*: `AppController`, `MoviesController`, custom `TabBarView` components, list layout components.
  - *State & Navigation*: `AppViewModel`, `MoviesViewModel`, `FavoritesViewModel`, `WatchHistoryViewModel`, `AppCoordinator`.
- **Player Domain**:
  - *UI/Interaction*: `VideoController`, `VideoPlayerOverlay`, `VideoSliderControl`
  - *Runtime Engines*: `QueueVideoPlayerEngine`
  - *State & Persistence*: `VideoViewModel`, `PlayerUseCase`, `PlaybackProgressManager`
- **Detail Domain**:
  - *Base UI*: `BaseDetailViewController`
  - *Movie Detail*: `MovieDetailViewController`, `MovieDetailViewModel`
  - *Series Detail*: `SerieDetailViewController`, `SerieDetailViewModel`
- **Settings Domain**:
  - *UI*: `SettingsViewController`, `SettingsViewModel`
  - *Business Logic*: `SettingsUseCase`
  - *Data layer*: `SettingsService`

---

## ▶️ Player Invariants (Do Not Break)

- **Overlay Auto-Hide**:
  - Use structured task cancellation (`Task.cancel`, `Task.isCancelled`) to manage the overlay's autohide timer. Never duplicate show/hide operations concurrently.
- **Seek Preview**:
  - Maintain a strict state machine (`idle` vs `previewing`).
  - Entering preview pauses playback and disables progress persistence.
  - Confirming or cancelling the preview must safely restore standard persistence behavior.
- **Resume Progress**:
  - If a video's progress fraction is `>= 0.93`, treat it as fully watched and do not prompt to resume.
  - If the progress is fresh (below stale threshold), auto-resume playback.
  - If progress is stale, present a dialog asking the user whether they'd like to resume or start over.
- **State Persistence**:
  - playback state must be saved on `viewWillDisappear` and during app backgrounding (`applicationWillResignActive`). Never rely on a single callback to persist user state.

---

## 🧪 Player Smoke Test Matrix (Run After Changes)

Run these checks manually in the simulator or device before completing a task:

1. **Overlay Timeout**: Verify movie playback starts and the UI overlay hides automatically after the timeout.
2. **Episode Selection**: Ensure selecting a specific episode from the details screen plays that exact episode, not S1E1.
3. **Seek Preview**:
   - Pressing Left/Right enters preview mode and shifts target seek time.
   - Pressing Select/Play confirms the seek and resumes playback.
   - Pressing Menu cancels the seek and returns to the initial position.
4. **Resume Prompting**:
   - Play a video partially. Close, reopen: fresh progress should auto-resume.
   - Stale progress should display a prompt dialog.
   - A video played beyond 93% should start from the beginning.
5. **Background Persistence**: Suspend/Background the app while playing. Re-open and verify playback state is recovered.

---

## 🧼 Refactor Triggers

- If a presentation controller file grows beyond **~400-500 lines**, decompose it by extracting auxiliary components, gestures, or protocols into small specialized classes/extensions.
- Prefer explicit protocols for UI managers to support decoupled test environments.

---

## 🛠 Suggested Refactoring & Improvement Roadmap

To enhance the codebase's health, keep it completely clean, and prepare for future scaling, we recommend targeting the following areas for improvements and refactoring:

### 1. 🔌 Eliminate Singleton Coupling in Presentation
- **Current status**: Presentation screens and ViewModels should not call infrastructure singletons directly. They are expected to receive managers, use cases, and repositories through `ModuleFactory` and `Container`.
- **Improvement**: Keep standardizing constructor injection across the Presentation layer. New dependencies must be exposed as protocol types from `Container`/`Factory`; do not add `.shared` lookups to screens or ViewModels.
- **Remaining debt**: Infrastructure-level singletons such as cache or UserDefaults helpers may still exist for legacy compatibility, but composition-owned services (including `CoreDataStack` and CoreData repositories) should be instantiated and wired by `Container`.

### 2. 🗃 Refactor Persistence Context Safety & Mapping
- **Issue**: CoreData operations in repository implementations can be prone to concurrency bugs if they don't strictly use context synchronization.
- **Improvement**: 
  - Ensure all database queries and context saves are systematically wrapped within `context.perform { ... }` or `context.performAndWait { ... }`.
  - Enforce a strict boundary where no `NSManagedObject` (e.g. `CDFavorite`, `CDHistory`) ever leaves the database repository layer. They must always be mapped to pure domain entities inside the repository on background threads before being delivered to the `UseCase` or `ViewModel`.

### 3. ✂️ Decompose Large Controllers & Views
- **Issue**: ViewControllers like `VideoController` and `BaseDetailViewController` are carrying extensive responsibilities (focus handling, gestures, data source setups, animations).
- **Improvement**: 
  - Decompose `VideoController` into single-responsibility objects such as `VideoGestureManager` (handles drag/swipe events) and `VideoFocusCoordinator` (manages player focus shifts).
  - Implement a declarative or helper-based Diffable Data Source approach to clean up extensive `UICollectionView` delegate boilerplate code.

### 4. ⚠️ Build Robust Domain Error Boundaries
- **Issue**: Low-level networking exceptions (`Alamofire.AFError`), XML parsing exceptions, or database failures can leak into the presentation layer or cause silent failures.
- **Improvement**: 
  - Implement a mapping layer inside `Data/Repository` that translates system and network errors into explicit domain errors (e.g., `DomainError.networkFailure`, `DomainError.unauthorized`, `DomainError.parsingFailed`).
  - ViewModels can then handle these structured errors and show helpful, localized messages to the user rather than passing generic `Error` objects.

### 5. 📡 Modernize Reactive Patterns with Swift Concurrency
- **Issue**: Combine is used extensively, which is excellent, but mixing standard `async`/`await` with complex Combine pipelines (especially using CheckedContinuations in UseCases) can create unnecessary overhead.
- **Improvement**:
  - Rely on Swift Concurrency (`AsyncStream` / `AsyncSequence`) in UseCases and Repositories to stream real-time events (like real-time search queries or persistent changes).
  - Use `@MainActor` annotations on ViewModels and ViewControllers to guarantee UI operations run on the main thread without manual `DispatchQueue.main.async` calls.

### 6. 🛡️ Eliminate Cross-Layer Dependencies (Clean Architecture Domain Isolation)
- **Issue**: `Theme.swift` in the `Domain` layer directly references `L10n` located in the `Infrastructure` layer (e.g. `L10n.Settings.Theme.dark`). In Clean Architecture, inner layers (Domain) must not depend on outer layers (Infrastructure).
- **Improvement**:
  - Extract display names to localizable formatting mapping logic in Presentation or presentation-facing configuration. The Domain entity should only contain the raw value or raw localized keys, not a direct dependency on `L10n` helper class from Infrastructure.

### 7. ⏳ Refactor Callback APIs to Swift Concurrency
- **Issue**: Several repository/service interfaces such as `SettingsRepositoryProtocol` still use legacy callback patterns (`fetchSettings(completion:)`). This forces the use of checked continuations (`withCheckedContinuation`) in Domain UseCases.
- **Improvement**:
  - Update `SettingsRepositoryProtocol` and `SettingsService` to expose asynchronous Swift Concurrency interfaces (e.g. `func fetchSettings() async throws -> SettingsData`) directly. This simplifies the Domain UseCases and improves overall compiler-checked thread-safety.

### 🧩 Architectural Goal Verification Matrix

| Area | Current Status | Target Architecture |
|---|---|---|
| **Domain Isolation** | Medium (Domain no longer imports UIKit/Combine directly, but `Theme` entity depends on `L10n` in Infrastructure) | High (zero UI/framework/infrastructure leakage, pure Swift/Foundation protocols/entities) |
| **DI Quality** | Medium (using lazy Container vars) | High (Strict constructor injection, zero singleton lookups in VM) |
| **Database Concurrency** | Medium (direct CoreData reads) | High (Strict background queue parsing, zero CD managed objects leaked) |
| **Player View Size** | Medium (~450 lines) | High (<300 lines via focus & gesture delegate extraction) |

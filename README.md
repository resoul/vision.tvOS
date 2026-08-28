# Vision

An elegant and modern **tvOS** application built with **Swift** and **UIKit** (100% programmatic, no Storyboards), featuring a clean and scalable **Multi-Provider Clean Architecture**.

Designed specifically for Apple TV, Vision delivers a fast, responsive, and cinematic experience with native focus engine optimization, custom video player, and unified content aggregation.

---

## ✨ Features

- 📺 **Native tvOS Experience**: Tailored UI and navigation designed specifically for Apple TV and Siri Remote.
- 🎛️ **Multi-Provider Architecture**: Modular integration of multiple online cinema providers (**Filmix**, **Kinobase**, **Seasonvar**) via [VisionProvider](https://github.com/resoul/VisionProvider.git).
- 🔄 **Reactive State Management**: Powered by [Flux](https://github.com/resoul/flux.git) for instant, reactive provider switching and UI synchronization.
- 🏷️ **Source Badging**: Visual provider badges on posters (`FILMIX`, `KINOBASE`, `SEASONVAR`) in unified listings.
- 📁 **Seasons & Episodes**: Full TV series support with seasons, episodes, and multiple voiceover/studio options.
- 🎥 **Custom Video Player**: HLS (m3u8) and MP4 video playback, quality selection (4K UHD, 1080p, 720p), audio track switcher, subtitle support, and resume playback.
- ⭐ **Unified Favorites & Watch History**: Persistent CoreData storage with automatic cross-provider resolution and playback resumption.
- 🔍 **Instant Search**: Fast and responsive search across active content sources.
- 🎨 **Dynamic Themes & Localization**: Dark/Light/Midnight themes and full multi-language support (`xcstrings`).
- 📦 **Top Shelf Extension**: Home screen spotlight showcasing trending and featured media.
- 🎯 **Focus Engine Optimization**: Smooth scaling, animations, and custom sound feedback on focus changes.

---

## 🏛 Architecture

The project follows **Clean Architecture** and **MVVM-C** principles with constructor-based Dependency Injection:

```
Vision/
│
├── App/                     # App lifecycle, Coordinator, DI Container, Module Factory
│   ├── AppDelegate.swift
│   ├── Container.swift
│   ├── Coordinator.swift
│   └── Factory.swift
│
├── Domain/                  # Pure business rules and entities
│   ├── Entity/              # ContentItem, ContentDetail, Category, Genre, PlaybackState
│   └── UseCase/             # GetContent, GetMovieDetail, Search, Player, Favorites, History
│
├── Data/                    # Repositories & persistence
│   ├── Repository/          # CoreData favorites, watch history, playback state
│   └── Service/             # Settings, Screenshots, Cache services
│
├── Infrastructure/          # Frameworks, networking & provider adapters
│   ├── ContentProviderProtocol.swift
│   ├── Providers/           # FilmixProvider, KinobaseProvider, SeasonvarProvider, VisionContentProvider
│   ├── Player/              # Video playback engine & overlay controls
│   ├── Persistence/         # CoreData stack
│   └── Theme & L10n/        # ThemeManager, LanguageManager, L10n
│
├── Presentation/            # UI layer (100% Programmatic UIKit)
│   └── Screens/
│       ├── App/             # TabBar navigation & dynamic category routing
│       ├── Movies/          # Grid view, poster collection cells, badge views
│       ├── Detail/          # Movie & Serie detail views, episode selectors
│       ├── Search/          # Search view controller & live results
│       ├── Video/           # Custom TV video player controller
│       └── Settings/        # Provider picker, cache settings, theme/language selection
│
└── TopShelfContent/         # Apple TV Top Shelf extension
```

---

## 🔌 Content Providers

Vision seamlessly aggregates content from multiple providers via **[VisionProvider](https://github.com/resoul/VisionProvider.git)**:

| Provider | Supported Categories | Video Formats | Features |
| :--- | :--- | :--- | :--- |
| **Filmix** | Movies, Series, Cartoons, Genres | HLS / MP4 | Quality selection up to 4K, multiple translations, ads info |
| **Kinobase** | Showcase (Main), Movies, Series, TV Shows, Animation | HLS (m3u8) | Multi-audio tracks, subtitles, quality switcher |
| **Seasonvar** | Showcase, Series | Direct MP4 | Multi-season support, voiceover selections |

---

## 🛠 Tech Stack

- **Platform**: tvOS 18+
- **Language**: Swift 6 (Strict Concurrency ready)
- **UI Framework**: UIKit (Programmatic Auto Layout, no Storyboards / XIBs)
- **State & Events**: [Flux](https://github.com/resoul/flux.git) (`Flux<T>`, `CurrentValueDistinct<T>`, `SubscriptionBag`)
- **Networking**: [Alamofire](https://github.com/Alamofire/Alamofire.git)
- **HTML Parsing**: [SwiftSoup](https://github.com/scinfu/SwiftSoup.git)
- **Persistence**: CoreData + Custom LRU Poster Cache
- **Media Playback**: AVKit & AVFoundation
- **Dependency Management**: Swift Package Manager (SPM)

---

## 🚀 Getting Started

### Prerequisites

- macOS 15+
- Xcode 16+
- Apple TV Simulator (tvOS 18.0+) or physical Apple TV 4K / HD

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/resoul/Vision.git
   cd Vision
   ```

2. Open the Xcode project:
   ```bash
   open Vision.xcodeproj
   ```

3. Xcode will automatically resolve package dependencies (`VisionProvider`, `Flux`, `Alamofire`, `SwiftSoup`).

4. Select scheme **Vision** -> target **Apple TV 4K (at 1080p)** simulator, and press **Run** (`⌘ + R`).

---

## 🤝 Contributing

Contributions, feature suggestions, and pull requests are welcome!

---

## 📄 License

This project is licensed under the MIT License.
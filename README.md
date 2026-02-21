# Muon Music Player 🎵

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

_Read this in other languages: [English](README.md), [繁體中文](README_zh.md)_

Muon is a minimalist, ad-free, offline-ready YouTube music and video player. The frontend is built with Flutter, powered by a standalone backend using FastAPI and yt-dlp.

## ✨ Features

- **Pure Ad-Free Experience**: No interruptions, no banners, just clean music.
- **No Account Required**: Search and access YouTube's vast library directly without logging in or subscribing.
- **Background & Lock Screen Playback**: Full support for iOS and Android background audio, Bluetooth controls, and lock screen media integration.
- **Music & Video Dual Support**: Not just for listening; download high-quality videos and switch to full-screen video playback with a single tap.
- **Offline Playback & Custom Playlists**: Download media to your local storage. Enjoy random or loop playback of your favorite playlists even without an internet connection.
- **Clean & Fluid UI**: Premium interface themed with YouTube Red, featuring smart marquee text and dynamic cover arts.

## 🛠️ Tech Stack (Frontend)

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) (Code Generation)
- **Media Playback**: [just_audio](https://pub.dev/packages/just_audio) & [audio_service](https://pub.dev/packages/audio_service) & [video_player](https://pub.dev/packages/video_player)
- **Local Database**: [Drift](https://drift.simonbinder.eu/) (SQLite)
- **Routing**: [go_router](https://pub.dev/packages/go_router)
- **Networking**: [Dio](https://pub.dev/packages/dio)

## 📁 Project Structure

This repository uses a frontend-driven monorepo architecture:

```text
muon/
├── android/          # Android platform-specific settings
├── ios/              # iOS platform-specific settings
├── backend/          # Standalone Python backend service (See backend/README.md)
├── lib/              # Flutter application source code
│   ├── app.dart
│   ├── audio/                # Background audio service & just_audio integration
│   ├── core/                 # Shared utilities and constants
│   ├── data/                 # Data layer (API, Drift DB, Repositories)
│   ├── presentation/         # UI Layer
│   │   ├── pages/            # Screens (Home, Search, Player, Settings)
│   │   ├── providers/        # Riverpod global state providers
│   │   └── widgets/          # Reusable UI components
│   └── main.dart
└── pubspec.yaml      # Flutter dependencies
```

## 🚀 Quick Start Guide

### 1. Start the Backend Service

The frontend app relies on the backend to parse and download files. Please refer to [backend/README.md](./backend/README.md) to start the FastAPI service first, and note your local or server IP address.

### 2. Run the Flutter App

1. **Install Flutter SDK** (Refer to the [official guide](https://docs.flutter.dev/get-started/install))
2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the App**:
   Replace `API_URL` below with your **actual backend IP address** (e.g., `http://192.168.1.100:8000`).
   ```bash
   flutter run --dart-define=API_URL=http://<YOUR_BACKEND_IP>:8000
   ```

### Code Generation (For Developers)

If you modify Riverpod (`@riverpod`) or Drift (`@DataClassName`) definitions, run `build_runner` to generate the corresponding `.g.dart` files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🌟 Contributing & Troubleshooting

- **iOS Black Screen / No Sound**: iOS changes the Sandbox UUID after re-compilation. `PathUtils` handles this automatically. If a video fails to play, it's usually due to incomplete default codecs (ensure the backend forces H.264+AAC downloads).
- **Android Compilation Warnings**: To suppress Java 8 deprecation warnings from third-party plugins, `build.gradle.kts` is configured with `-Xlint:-options`.

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the [LICENSE](LICENSE) file for details.

---

_Built for the pure joy of listening._

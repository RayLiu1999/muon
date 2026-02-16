# OfflineYT Player

## 專案概述

離線 YouTube 播放器 App，使用 Flutter 開發，支援 YouTube 搜尋、音訊/影片下載、本地媒體庫管理與背景播放。詳細規格見 [SPEC.md](./SPEC.md)。

## 技術棧

| 類別     | 選定方案                         |
| -------- | -------------------------------- |
| 框架     | Flutter (Dart)                   |
| 狀態管理 | Riverpod（使用 code generation） |
| 路由     | go_router                        |
| 資料庫   | drift (SQLite)                   |
| 音訊播放 | just_audio + audio_service       |
| 影片播放 | media_kit（v0.2）                |
| HTTP     | dio                              |
| 背景服務 | flutter_background_service       |

## 專案結構（規劃）

```
lib/
├── main.dart
├── app.dart                    # MaterialApp + GoRouter 設定
├── core/                       # 共用核心
│   ├── constants/              # 常數定義
│   ├── theme/                  # 主題設定
│   ├── utils/                  # 工具函式
│   └── extensions/             # Dart extensions
├── data/                       # 資料層
│   ├── database/               # drift 資料庫定義
│   │   ├── app_database.dart
│   │   ├── tables/             # 資料表定義
│   │   └── daos/               # Data Access Objects
│   ├── repositories/           # Repository 實作
│   └── services/               # 外部服務（API、下載）
├── domain/                     # 領域層
│   ├── models/                 # 領域模型
│   └── repositories/           # Repository 抽象介面
├── presentation/               # UI 層
│   ├── providers/              # Riverpod Providers
│   ├── pages/                  # 頁面
│   │   ├── home/
│   │   ├── search/
│   │   ├── player/
│   │   ├── playlist/
│   │   ├── download/
│   │   └── settings/
│   └── widgets/                # 共用元件
│       ├── mini_player.dart
│       └── ...
└── audio/                      # 音訊服務
    └── audio_handler.dart      # AudioHandler 實作
```

## 程式碼慣例

- **語言**：Dart，遵循 [Effective Dart](https://dart.dev/effective-dart) 風格
- **Lint**：使用 `flutter_lints` 或 `very_good_analysis`
- **命名**：
  - 檔案名：`snake_case.dart`
  - 類別名：`PascalCase`
  - 變數/函式：`camelCase`
  - 常數：`camelCase`（Dart 慣例，非 UPPER_SNAKE）
- **註解**：使用繁體中文
- **Provider 命名**：`xxxProvider`（如 `playerProvider`、`mediaLibraryProvider`）
- **狀態管理**：使用 Riverpod `@riverpod` annotation（code generation 模式）
- **不可變狀態**：使用 `freezed` 產生 immutable data class

## 常用指令

```bash
# 執行 App
flutter run

# 產生程式碼（drift、freezed、riverpod_generator）
dart run build_runner build --delete-conflicting-outputs

# 監聽式產生程式碼
dart run build_runner watch --delete-conflicting-outputs

# 執行測試
flutter test

# 分析程式碼
flutter analyze
```

## 注意事項

- 所有 API Key 不可寫死在程式碼中，使用 `--dart-define` 或 `.env` 檔案
- 背景播放是核心功能，修改 `audio_handler.dart` 時需格外謹慎
- drift 資料表修改後需跑 `build_runner` 重新產生程式碼
- 影片播放功能屬 v0.2 範圍，v0.1 先不實作

# Muon Music Player 🎵

Muon 是一個極簡、無廣告、支援離線播放的 YouTube 音樂/影片播放器。專案採用 Flutter 開發前端，並搭配 FastAPI 與 yt-dlp 構建獨立的後端下載服務。

## ✨ 核心特色

- **純粹的無廣告體驗**：沒有中斷、沒有橫幅，只有乾淨的音樂。
- **免帳號訂閱**：透過搜尋直接取得 YouTube 上的豐富資源，無須註冊登入。
- **背景播放與通知列控制**：完全支援 iOS 與 Android 的背景播放、藍牙耳機線控、鎖屏音樂控制。
- **雙棲支援 (音樂 & 影片)**：不僅能聽歌，下載高畫質影片後亦可一鍵切換至全螢幕影片觀看。
- **離線播放與自建清單**：支援下載到本地端，沒有網路也能隨機或循環播放你最愛的歌單。
- **乾淨流暢的 UI**：以 YouTube 紅色調打造的質感介面，包含智慧跑馬燈、動態封面圖等巧思。

## 🛠️ 技術棧 (Frontend)

- **框架**: [Flutter](https://flutter.dev/) (Dart)
- **狀態管理**: [Riverpod](https://riverpod.dev/) (Code Generation)
- **多媒體播放**: [just_audio](https://pub.dev/packages/just_audio) & [audio_service](https://pub.dev/packages/audio_service) & [video_player](https://pub.dev/packages/video_player)
- **本地資料庫**: [Drift](https://drift.simonbinder.eu/) (SQLite)
- **路由導航**: [go_router](https://pub.dev/packages/go_router)
- **網路請求**: [Dio](https://pub.dev/packages/dio)

## 📁 專案結構

此 Repository 採用前端驅動的 Monorepo 架構：

```text
muon/
├── android/          # Android 平台專屬設定與編譯
├── ios/              # iOS 平台專屬設定與編譯
├── backend/          # Python 獨立後端服務 (請參閱 backend/README.md)
├── lib/              # Flutter 應用程式原始碼
│   ├── app.dart              # App 根元件與主題設定
│   ├── audio/                # 背景音訊服務與 just_audio 介接
│   ├── core/                 # 共用工具與常數設定 (如: PathUtils)
│   ├── data/                 # 資料層 (API 介面、本機 Drift DB、Repository)
│   ├── presentation/         # 畫面呈現層
│   │   ├── pages/            # 各個獨立畫面 (首頁、搜尋、播放器、設定)
│   │   ├── providers/        # 河圖 (Riverpod) 的全域狀態提供者
│   │   └── widgets/          # 重複使用的 UI 元件 (如 MiniPlayer, AutoScrollText)
│   └── main.dart             # 程式進入點
└── pubspec.yaml      # Flutter 依賴清單
```

## 🚀 快速啟動指南

### 1. 啟動後端服務

前端 App 必須仰賴後端解析與下載檔案。請先前往 [backend/README.md](./backend/README.md) 啟動 FastAPI 服務，並取得你的本機或伺服器 IP。

### 2. 啟動 Flutter 應用

1. **安裝 Flutter SDK** (若尚無安裝請參考[官方指南](https://docs.flutter.dev/get-started/install))
2. **安裝依賴套件**:
   ```bash
   flutter pub get
   ```
3. **執行程式**：
   請替換下方指令的 `API_URL` 為你**後端實際運作的 IP 網址**（如果是區域網路，請填上如 `http://192.168.1.100:8000`）。
   ```bash
   flutter run --dart-define=API_URL=http://<YOUR_BACKEND_IP>:8000
   ```

### 重新生成程式碼 (開發者)

如果你修改了 Riverpod (`@riverpod`) 或 Drift (`@DataClassName`) 的定義，你需要執行 build_runner 來產生對應的 `.g.dart` 程式檔案：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🌟 貢獻與除錯

- **iOS 黑屏/無聲音**：iOS 會在重新編譯後改變 Sandbox UUID，`PathUtils` 已解決此問題。影片若有異常，大多因為預設編碼不完整（請確認後端已強制下載 H.264+AAC）。
- **Android 編譯警告**：若因 Java 8 廢棄導致警告，專案的 `build.gradle.kts` 已配置 `-Xlint:-options` 抑制第三方套件警告。

---

_Built for the pure joy of listening._

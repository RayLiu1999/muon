# Muon 專案教學 (1)：專案架構與基礎觀念

這份文件專為 Flutter 新手設計，帶你從零開始了解 Muon 這個專案究竟做了什麼、為什麼要這樣做，以及我們選用的核心技術。

---

## 1. Muon 是什麼？

Muon 是一個「離線 Youtube 音樂播放器」。我們的目標是讓使用者可以：

1. 搜尋 Youtube 音樂
2. 下載到手機本機（m4a 格式）
3. 無網路也能聆聽，支援背景播放和通知列控制

為了達成這個目標，專案會涵蓋：**網路請求**、**本機資料庫**、**背景音訊控制**、**狀態管理**。

---

## 2. 核心技術選型 (Tech Stack)

在開發 Flutter App 時，有很多套件可以選擇。Muon 選用了目前社群極力推薦的現代化組合：

### 狀態管理：**Riverpod**

在 Flutter 中，當資料改變時，UI ต้อง跟著更新（例如：下載進度 0% 變 100%）。Riverpod 是目前最穩健的狀態管理工具，我們搭配了 `riverpod_generator`，只要加上 `@riverpod` 標籤，程式碼碼產生器就會幫我們寫好繁瑣的設定程式碼。

### 路由管理：**go_router**

當 App 有多個頁面（首頁、搜尋頁、設定頁、播放器頁）時，我們需要一個導航系統。`go_router` 支援巢狀路由（StatefulShellRoute），非常適合用來實作帶有「底部導航列 (BottomNavigationBar)」的 App，能讓切換 Tab 時保留各個頁面的狀態。

### 本機資料庫：**drift**

用來儲存已下載的歌曲清單、使用者的播放清單、播放記錄等。Drift 是 Flutter 上最強大的 SQLite 封裝套件，能將 SQL 語法轉換為 Dart 的物件操作（ORM），並且寫入/讀取都是非同步的，不會卡住畫面。

### 音訊處理：**just_audio + audio_service**

- `just_audio`：負責底層的音樂播放（播放、暫停、調進度）。
- `audio_service`：負責與手機系統溝通。當 App 退到背景時，通知系統（Android/iOS）顯示音樂控制面板，並攔截耳機按鈕的事件。

---

## 3. 資料夾結構解析 (Directory Structure)

Muon 採用了類似「Feature-First」（依功能分）與「Layer-First」（依分層分）混合的架構，確保程式碼好找且好維護。

```text
lib/
├── app.dart                  # App 的根 Widget，負責設定 Router 和 Theme
├── main.dart                 # 程式進入點，負責初始化全域服務 (資料庫, 音訊)
│
├── audio/                    # 音訊處理核心
│   └── audio_handler.dart    # 將 just_audio 與 audio_service 綁定的地方
│
├── core/                     # 核心共用元件 (任何地方都可能用到)
│   ├── constants/            # 全域常數（例如：系統播放清單的靜態 ID）
│   ├── theme/                # UI 樣式設定（顏色、字體設定）
│   └── utils/                # 工具函式（例如：把毫秒轉成 "03:45" 的字串）
│
├── data/                     # 資料與邏輯層
│   ├── database/             # Drift 資料庫相關
│   │   ├── daos/             # Data Access Objects (負責操作特定資料表的工具)
│   │   ├── tables/           # 資料表結構定義
│   │   └── app_database.dart # 資料庫主體
│   ├── models/               # 一般資料模型（例如：搜尋結果的 SearchResult）
│   ├── repositories/         # 資源庫（封裝 DAO 或網路請求，提供給 UI 層乾淨的介面）
│   └── services/             # 外部服務整合（例如：YouTube API 搜尋、模擬下載）
│
└── presentation/             # 畫面與 UI 層
    ├── pages/                # 獨立的畫面 (Screens)
    │   ├── home/             # 媒體庫首頁
    │   ├── player/           # 全螢幕播放器
    │   ├── search/           # 搜尋頁面
    │   └── settings/         # 設定頁面
    ├── providers/            # Riverpod 的狀態提供者 (連接 Logic 與 UI)
    └── widgets/              # 可重複使用的 UI 元件 (如 MiniPlayer, AppShell)
```

---

## 4. 這與傳統開發有什麼不同？

如果你曾寫過一點點 Flutter，可能習慣把所有變數和邏輯都塞進 `StatefulWidget` 裡面，然後不斷呼叫 `setState`。

在 Muon 中，我們**嚴格分離**了「資料層」與「UI 層」：

1. **資料要怎麼拿**：寫在 `data/` 裡面。
2. **資料狀態要怎麼給 UI**：寫在 `presentation/providers/` 裡面。
3. **UI 怎麼畫**：寫在 `presentation/pages/` 裡面，使用 `ConsumerWidget` 監聽 Provider 接資料。

這樣做的好處是，當你要改 UI 顏色時，不會不小心弄壞資料庫邏輯；當你要寫測試時，可以直接測試資料庫邏輯，不需要啟動模擬器看 UI。

**下一篇，我們將深入了解 `AppDatabase` 和 Drift 資料庫是如何運作的！**

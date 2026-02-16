# OfflineYT Player — 產品規格書

## 一、產品簡介

- **名稱（暫定）**：OfflineYT Player
- **目標平台**：Android（優先），未來可擴 iOS
- **主要目的**：
  - 透過 YouTube 搜尋並下載影音到本機
  - 以 Spotify 類似體驗播放本機影音（音樂／影片），支援播放清單、我的最愛
  - 支援穩定背景播放（鎖屏、切 App、通知列控制）

> [!WARNING]
> 法規／TOS 提醒：從 YouTube 下載內容並離線播放，可能違反 YouTube 使用條款；本工具規劃以個人學習／實驗為前提，不建議公開發佈或商用。

---

## 二、系統架構與技術選型

### 前端／App：Flutter

| 類別      | 選定方案               | 理由                                                                                        |
| --------- | ---------------------- | ------------------------------------------------------------------------------------------- |
| 狀態管理  | **Riverpod**           | Provider 作者已推薦遷移至 Riverpod；`AsyncNotifier` 更適合 `audio_service` 等複雜非同步狀態 |
| 路由      | **go_router**          | Flutter 官方推薦，Navigator 2.0 原生 API 太繁瑣                                             |
| 資料庫    | **drift**              | 型別安全 query、自動 migration、DAO 抽象，適合 MediaItem + Playlist 多表關聯場景            |
| Key-Value | **shared_preferences** | 儲存上次播放狀態等簡單設定                                                                  |
| 檔案路徑  | **path_provider**      | 下載到 App 專用目錄，避免被相簿掃到                                                         |

### 播放核心

| 套件                                                    | 用途                                                            |
| ------------------------------------------------------- | --------------------------------------------------------------- |
| [just_audio](https://pub.dev/packages/just_audio)       | 音訊播放（支援本機檔案）                                        |
| [audio_service](https://pub.dev/packages/audio_service) | 背景播放、通知列、鎖屏控制、耳機按鈕                            |
| [audio_session](https://pub.dev/packages/audio_session) | Audio Focus 管理（Android / iOS）                               |
| [media_kit](https://pub.dev/packages/media_kit)         | 影片播放（基於 libmpv，效能優於官方 `video_player`），v0.2 導入 |

### 下載與 YouTube 解析

| 類別         | 選定方案                                       | 理由                                                                                           |
| ------------ | ---------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| YouTube 搜尋 | **YouTube Data API v3**                        | 官方正規，結果排序品質好；每日 quota 10,000 units（每次 search 消耗 100），個人用足夠          |
| 影音下載     | **自建 REST API（VPS + yt-dlp）**              | App 呼叫後端 API 取得 direct URL 或檔案。避免在 Android 上跑 yt-dlp 的部署複雜度與版本更新困難 |
| App 端下載   | **dio**                                        | 支援斷點續傳、下載進度回報                                                                     |
| 背景下載     | **flutter_background_service + dio + Isolate** | `workmanager` 僅適合週期性短任務，不適合大檔案下載                                             |

### 架構總覽

```
┌─────────────────────────────────────────────┐
│                 Flutter App                  │
│  ┌─────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ Riverpod│ │ go_router│ │   drift DB   │  │
│  └────┬────┘ └──────────┘ └──────┬───────┘  │
│       │                          │           │
│  ┌────▼─────────────────────┐    │           │
│  │    AudioHandler          │    │           │
│  │  (audio_service +        │    │           │
│  │   just_audio / media_kit)│    │           │
│  └──────────────────────────┘    │           │
│                                  │           │
│  ┌───────────────────┐    ┌──────▼───────┐   │
│  │  DownloadService  │    │ MediaRepo    │   │
│  │  (dio + isolate)  │    │ PlaylistRepo │   │
│  └────────┬──────────┘    └──────────────┘   │
└───────────┼──────────────────────────────────┘
            │
    ┌───────▼────────┐
    │  自建 REST API  │
    │  (VPS + yt-dlp) │
    └────────────────┘
```

---

## 三、核心功能需求

### 1. YouTube 搜尋與下載

#### 1.1 搜尋功能

- 使用者可以輸入關鍵字搜尋 YouTube 影片
- 顯示搜尋結果列表：
  - 縮圖、標題、頻道名稱、影片長度
  - 是否已下載（用 icon 標示）
- 點擊單一結果可進入「影片詳情頁」
- 搜尋方式：透過 YouTube Data API v3，API Key 存於環境變數 / 後端代理

#### 1.2 下載功能

- 在搜尋結果列表或影片詳情頁，提供「下載」按鈕
- 下載選項：
  - 僅音訊（預設，e.g. m4a）
  - 影音（mp4，v0.2 支援）
- 顯示下載進度
  - 全域「下載佇列頁」：顯示所有下載中／已完成／失敗項目
  - 支援暫停／繼續／取消下載
- 下載完成後：
  - 寫入本地資料庫（MediaItem 資料表）
  - 自動加入「最近下載」系統播放清單

#### 1.3 錯誤處理

- 網路錯誤、yt-dlp 失敗、API 回傳錯誤時，要有 SnackBar 錯誤提示
- 已下載過同一影片時，提供選項：略過、覆蓋（預設：略過並提示）

---

### 2. 資料模型定義

#### 2.1 MediaItem（媒體項目）

| 欄位            | 型別          | 說明                       |
| --------------- | ------------- | -------------------------- |
| `id`            | TEXT (UUID)   | App 內部主鍵               |
| `sourceId`      | TEXT          | YouTube 影片 ID            |
| `title`         | TEXT          | 標題                       |
| `channel`       | TEXT          | 頻道名稱                   |
| `durationMs`    | INTEGER       | 時長（毫秒）               |
| `filePath`      | TEXT          | 本機檔案路徑               |
| `thumbnailPath` | TEXT          | 縮圖本機快取路徑           |
| `fileSize`      | INTEGER       | 檔案大小（bytes）          |
| `isVideo`       | INTEGER (0/1) | 是否為影片                 |
| `favorite`      | INTEGER (0/1) | 是否我的最愛               |
| `createdAt`     | INTEGER       | 下載時間（Unix timestamp） |
| `lastPlayedAt`  | INTEGER       | 最後播放時間               |
| `playCount`     | INTEGER       | 播放次數                   |

#### 2.2 Playlist（播放清單）

| 欄位        | 型別            | 說明                                  |
| ----------- | --------------- | ------------------------------------- |
| `id`        | TEXT (UUID)     | 主鍵                                  |
| `name`      | TEXT            | 清單名稱                              |
| `type`      | TEXT            | `system` / `user`（系統清單不可刪除） |
| `coverPath` | TEXT (nullable) | 封面路徑                              |
| `createdAt` | INTEGER         | 建立時間                              |
| `updatedAt` | INTEGER         | 最後更新時間                          |

#### 2.3 PlaylistItem（清單 ↔ 媒體 多對多關聯）

| 欄位          | 型別        | 說明                   |
| ------------- | ----------- | ---------------------- |
| `id`          | TEXT (UUID) | 主鍵                   |
| `playlistId`  | TEXT (FK)   | 對應 Playlist.id       |
| `mediaItemId` | TEXT (FK)   | 對應 MediaItem.id      |
| `sortOrder`   | INTEGER     | 排序位置（拖拉排序用） |
| `addedAt`     | INTEGER     | 加入時間               |

#### 2.4 DownloadTask（下載任務）

| 欄位           | 型別            | 說明                                                         |
| -------------- | --------------- | ------------------------------------------------------------ |
| `id`           | TEXT (UUID)     | 主鍵                                                         |
| `sourceId`     | TEXT            | YouTube video ID                                             |
| `title`        | TEXT            | 影片標題                                                     |
| `thumbnailUrl` | TEXT            | 縮圖 URL                                                     |
| `status`       | TEXT            | `queued` / `downloading` / `paused` / `completed` / `failed` |
| `progress`     | REAL            | 0.0 ~ 1.0                                                    |
| `filePath`     | TEXT (nullable) | 目標路徑                                                     |
| `format`       | TEXT            | `audio` / `video`                                            |
| `errorMessage` | TEXT (nullable) | 失敗原因                                                     |
| `createdAt`    | INTEGER         | 建立時間                                                     |

---

### 3. 本地媒體庫與播放器（類 Spotify 體驗）

#### 3.1 媒體庫瀏覽

- 「首頁」分為幾個 section：
  - 最近播放
  - 最近下載
  - 我的最愛
  - 播放清單列表
- 支援排序與篩選：
  - 依標題／下載時間／頻道／播放次數排序
  - 篩選：音訊／影片

#### 3.2 播放清單（Playlist）

- 功能：
  - 建立／重新命名／刪除播放清單
  - 播放清單內新增／移除曲目（MediaItem）
  - 調整曲目順序（拖拉排序）
- 系統清單（`type = system`，唯讀，不可刪除）：
  - 「全部歌曲」
  - 「最近下載」
  - 「我的最愛」

#### 3.3 我的最愛

- 任何 MediaItem 可以「加入／移除我的最愛」
- 「我的最愛」視為一個系統播放清單

#### 3.4 播放器 UI 功能

- 基本控制：播放／暫停／上一首／下一首／進度條拖曳
- 循環模式：單曲循環、全部循環、隨機播放
- 顯示內容：
  - 縮圖、標題、頻道名稱
  - 當前進度／總長度
- 影片播放（v0.2）：
  - 若為影片檔，可切換模式：
    - 音訊模式：只顯示封面
    - 影片模式：顯示影片畫面（支援全螢幕，使用 `media_kit`）

#### 3.5 資料管理

- 在媒體詳情頁可以：
  - 刪除本地檔案（同步刪 DB 記錄）
  - 編輯標題（v0.3 進階功能）
- 提供「儲存空間管理」頁（v0.2）：
  - 顯示總大小、各播放清單大小、單一檔案大小
  - 一鍵刪除「很久沒播」「超過 N 個月的下載」

---

### 4. 背景播放（最重要）

#### 4.1 背景播放行為

- App 切到背景、螢幕關閉時：
  - 音樂繼續播放
  - Android 通知列出現播放控制：上一首／播放／暫停／下一首，顯示封面／標題／頻道
- 從通知列可以：
  - 控制播放／暫停／切歌
  - 點擊通知回到 App 播放器頁

#### 4.2 系統整合需求

- 使用 `audio_service` + `just_audio` 實作 `AudioHandler`，對應 Android `MediaSession`：
  - 支援耳機線控／藍牙裝置按鍵（單擊暫停／播放，雙擊下一首）
  - 支援 Audio Focus 互斥（例如 YouTube / Spotify 播放時本 App 自動暫停）
- App 被系統殺掉時：
  - 短時間內可維持播放（前景 service 模式）
  - 若被完全殺死，音樂停止是可接受行為，但要在下次開啟 App 時恢復播放列表與進度

#### 4.3 後台啟動與續播

- App 啟動時：
  - 若有未完成的播放佇列與進度，詢問使用者是否「繼續上次播放」
- Auto-Resume 選項：
  - 設定內提供：開啟 App 是否自動接續播放

---

## 四、畫面與導航架構

### 導航結構

```
┌─────────────────────────────────────────┐
│              App Shell                   │
│  ┌─────────────────────────────────────┐ │
│  │         頁面內容區域                 │ │
│  │  (go_router 管理的子頁面)            │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────────────────────────┐ │
│  │  Mini Player（全域 persistent）      │ │
│  │  當前曲目 + 播放/暫停 + 進度條       │ │
│  │  ↑ 點擊展開全螢幕播放器              │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────────────────────────┐ │
│  │  BottomNavigationBar                │ │
│  │  🏠 首頁  │  🔍 搜尋  │  ⚙️ 設定    │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

> Mini Player 位於 `BottomNavigationBar` 上方，包在 `ShellRoute` 外層，確保全域可見。

### 頁面清單

1. **首頁（媒體庫）** — Tab: 🏠
   - Tabs 或 Segmented：全部／我的最愛／播放清單
   - 本地搜尋框（搜尋已下載的媒體，非 YouTube）

2. **YouTube 搜尋頁** — Tab: 🔍
   - 輸入框＋搜尋按鈕
   - 結果列表（含下載按鈕與已下載標示）
   - AppBar action → 下載佇列頁入口

3. **下載佇列頁**（從搜尋頁進入）
   - 分段：下載中／已完成／失敗
   - 支援重試／刪除

4. **播放清單管理頁**（從首頁進入）
   - 清單列表
   - 進入單一清單後編輯曲目

5. **播放器頁**
   - 底部 mini player → 點擊展開全螢幕播放器
   - 全螢幕播放器：封面、控制列、播放佇列

6. **設定頁** — Tab: ⚙️
   - 下載偏好（音訊／影片預設格式）
   - 省流量模式（僅 Wi‑Fi 下載）
   - 自動繼續播放開關
   - 儲存空間管理入口

---

## 五、非功能性需求

| 類別       | 指標                                                           |
| ---------- | -------------------------------------------------------------- |
| **效能**   | 播放切歌延遲 < 300ms（本機檔案）                               |
| **效能**   | 首次啟動時間 < 3 秒（不含資料庫冷啟動）                        |
| **穩定性** | 背景播放 1 小時以上無明顯 memory leak / crash                  |
| **穩定性** | 大量曲目（5,000 首）時，媒體庫列表仍能流暢滾動（搭配分頁載入） |
| **儲存**   | 下載檔案存在 App 專用目錄（避免被相簿掃到）                    |
| **安全**   | 不要求登入，不存敏感個資（初期版本）；API Key 不寫死在程式碼中 |

---

## 六、MVP 版本規劃

### v0.1 — 核心可用（首要目標）

- [x] 自建 REST API（VPS + yt-dlp）
- [ ] YouTube 搜尋（Data API v3）
- [ ] 音訊下載（m4a）+ 下載佇列
- [ ] 本地媒體庫列表
- [ ] 基本播放器（播放 / 暫停 / 上下首 / 進度條）
- [ ] 背景播放 + Android 通知列控制
- [ ] 我的最愛
- [ ] drift 資料庫（MediaItem, Playlist, PlaylistItem, DownloadTask）

### v0.2 — 體驗提升

- [ ] 影片下載 + 播放（media_kit 整合）
- [ ] 播放清單 CRUD + 拖拉排序
- [ ] 儲存空間管理頁
- [ ] 省流量模式（僅 Wi-Fi 下載）
- [ ] 下載斷點續傳

### v0.3 — 進階功能

- [ ] 匯出／匯入播放清單（JSON）
- [ ] 歌詞支援（LRC 檔解析）
- [ ] 睡眠定時（定時關閉）
- [ ] 編輯標題／自訂 tag

### 未來方向

- 多裝置同步（自建後端 + 帳號系統）
- iOS 支援
- 智慧推薦（依播放歷史）

---

## 七、主要 Dart Class 對應（預覽）

```dart
// 資料模型（drift 會自動產生）
// - MediaItem → media_items 表
// - Playlist → playlists 表
// - PlaylistItem → playlist_items 表
// - DownloadTask → download_tasks 表

// 核心服務
// - AudioHandler（extends BaseAudioHandler）→ 播放核心
// - DownloadService → 下載管理
// - YtApiService → YouTube 搜尋 API
// - YtDlpApiService → 自建後端 API 互動

// Repository 層
// - MediaRepository → MediaItem CRUD
// - PlaylistRepository → Playlist + PlaylistItem CRUD
// - DownloadRepository → DownloadTask CRUD

// Riverpod Provider
// - playerProvider → 播放器狀態
// - mediaLibraryProvider → 媒體庫列表
// - downloadQueueProvider → 下載佇列狀態
// - searchProvider → YouTube 搜尋結果
```

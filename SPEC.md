## 一、產品簡介

- 名稱（暫定）：OfflineYT Player
- 目標平台：Android（優先），未來可擴 iOS
- 主要目的：
  - 透過 YouTube 搜尋並下載影音到本機
  - 以 Spotify 類似體驗播放本機影音（音樂／影片），支援播放清單、我的最愛
  - 支援穩定背景播放（鎖屏、切 App、通知列控制） [pub](https://pub.dev/packages/audio_service)

> 法規／TOS 提醒：從 YouTube 下載內容並離線播放，可能違反 YouTube 使用條款；本工具規劃以個人學習／實驗為前提，不建議公開發佈或商用。

---

## 二、系統架構與技術選型（高階）

- 前端／App：Flutter
  - 狀態管理：Riverpod / Provider（二擇一）
  - 路由：go_router / Navigator 2.0
- 播放核心（跨平台）：
  - `just_audio`：實際音訊播放（支援本機檔案） [pub](https://pub.dev/packages/audio_service)
  - `audio_service`：背景播放、通知列、鎖屏控制、耳機按鈕支援 [vibe-studio](https://vibe-studio.ai/insights/background-audio-playback-and-media-controls-in-flutter)
  - `audio_session`：管理 Audio focus / AVAudioSession（未來做 iOS 時用得到） [pub](https://pub.dev/packages/audio_service)
- 資料儲存：
  - Metadata & 設定：`sqflite` 或 `drift`（SQLite）
  - 簡單 key-value（例如上次播放狀態）：`shared_preferences`
  - 檔案路徑：`path_provider`（下載到 app 專用目錄）
- 下載與 YouTube 解析：
  - 做法 A：App 呼叫你自己在手機／後端包好的 yt-dlp（Termux／自建 API）
  - 做法 B：在後端（VPS）包 yt-dlp 成簡單 REST API，App 只打 API 取得 direct URL 或檔案
- 背景下載：
  - Flutter `Isolate` 或使用 `workmanager` 做背景任務（可在 App 關掉時續傳）

---

## 三、核心功能需求

### 1. YouTube 搜尋與下載

1.1 搜尋功能

- 使用者可以輸入關鍵字搜尋 YouTube 影片
- 顯示搜尋結果列表：
  - 縮圖、標題、頻道名稱、影片長度
  - 是否已下載（用 icon 標示）
- 點擊單一結果可進入「影片詳情頁」

  1.2 下載功能

- 在搜尋結果列表或影片詳情頁，提供「下載」按鈕
- 下載選項：
  - 僅音訊（預設，e.g. mp3 / m4a）
  - 影音（mp4，給你有時想看 MV）
- 顯示下載進度
  - 全域「下載佇列頁」：顯示所有下載中／已完成／失敗項目
  - 支援暫停／繼續／取消下載
- 下載完成後：
  - 寫入本地資料庫（MediaItem 資料表）
  - 自動建立預設播放清單（例如「最近下載」）

    1.3 錯誤處理

- 網路錯誤、yt-dlp 失敗、API 回傳錯誤時，要有 toast／錯誤提示
- 已下載過同一影片時，提供選項：略過、覆蓋、建立重複一份（預設：略過並提示）

---

### 2. 本地資料庫與播放器（類 Spotify 體驗）

2.1 媒體資料模型（MediaItem）  
欄位（初版，可以對應 SQLite schema）：

- `id`：App 內部 UUID
- `sourceId`：YouTube 影片 ID
- `title`：標題
- `channel`：頻道名稱
- `durationMs`：時長
- `filePath`：本機檔案路徑（音訊或影片）
- `thumbnailPath`：縮圖本機快取路徑
- `isVideo`：是否為影片
- `favorite`：是否我的最愛
- `createdAt`：下載時間
- `lastPlayedAt`：最後播放時間
- `playCount`：播放次數

  2.2 媒體庫瀏覽

- 「首頁」分為幾個 section：
  - 最近播放
  - 最近下載
  - 我的最愛
  - 播放清單列表
- 支援排序與篩選：
  - 依標題／下載時間／頻道／播放次數排序
  - 篩選：音訊／影片

    2.3 播放清單（Playlist）

- 功能：
  - 建立／重新命名／刪除播放清單
  - 播放清單內新增／移除曲目（MediaItem）
  - 調整曲目順序（拖拉排序）
- 特殊清單：
  - 系統自動產生：「全部歌曲」「最近下載」「我的最愛」等（唯讀或限制刪除）

    2.4 我的最愛

- 任何 MediaItem 可以「加入／移除我的最愛」
- 「我的最愛」視為一個特殊播放清單

  2.5 播放器 UI 功能

- 基本控制：播放／暫停／上一首／下一首／進度條拖曳／循環模式（單曲循環、全部循環、隨機）
- 顯示內容：
  - 縮圖、標題、頻道名稱
  - 當前進度／總長度
  - 是否為影片（影片可選擇「只聽音訊」模式）
- 影片播放：
  - 若是影片檔，可在「播放器頁」切換：
    - 音訊模式：只顯示封面
    - 影片模式：顯示影片畫面（支援全螢幕）

    2.6 資料管理

- 在媒體詳情頁可以：
  - 刪除本地檔案（同步刪 DB 記錄）
  - 編輯標題／自訂 tag（非必要，可做為進階功能）
- 提供「儲存空間管理」頁：
  - 顯示總大小、各播放清單大小、單一檔案大小
  - 一鍵刪除「很久沒播」「超過 N 個月的下載」

---

### 3. 背景播放（最重要）

3.1 背景播放行為

- App 切到背景、螢幕關閉時：
  - 音樂繼續播放
  - Android 通知列出現播放控制：上一首／播放／暫停／下一首，顯示封面／標題／頻道 [vibe-studio](https://vibe-studio.ai/insights/background-audio-playback-and-media-controls-in-flutter)
- 從通知列可以：
  - 控制播放／暫停／切歌
  - 點擊通知回到 App 播放器頁

    3.2 系統整合需求

- 使用 `audio_service` + `just_audio` 實作 `AudioHandler`，對應 Android 的 `MediaSession`：
  - 支援耳機線控／藍牙裝置按鍵（單擊暫停／播放，雙擊下一首）。 [vibe-studio](https://vibe-studio.ai/insights/background-audio-playback-and-media-controls-in-flutter)
  - 支援其他 App 播放音樂時的 Audio Focus 互斥（例如 YouTube / Spotify 播放時本 App 自動暫停） [pub](https://pub.dev/packages/audio_service)
- App 被系統殺掉時：
  - 短時間內可維持播放（前景 service 模式）
  - 若被完全殺死，音樂停止是可接受行為，但要在下次開啟 App 時恢復播放列表與進度

    3.3 後台啟動與續播

- App 啟動時：
  - 若有未完成的播放隊列與進度，問使用者是否「繼續上次播放」
- Auto-Resume 選項：
  - 設定內提供：開啟 App 是否自動接續播放

---

## 四、畫面與流程（概要）

1. **首頁（媒體庫）**
   - Tabs 或 Segmented：全部／我的最愛／播放清單
   - 搜尋框（針對本地資料搜尋，不是 YouTube）

2. **YouTube 搜尋頁**
   - 輸入框＋搜尋按鈕
   - 結果列表（含下載按鈕與已下載標示）

3. **下載佇列頁**
   - 分段：下載中／已完成／失敗
   - 支援重試／刪除

4. **播放清單管理頁**
   - 清單列表
   - 進入單一清單後編輯曲目

5. **播放器頁（底部 mini player + 全螢幕 player）**
   - 底部 mini player：顯示當前曲目＋播放／暫停
   - 點擊展開全螢幕播放器

6. **設定頁**
   - 下載偏好（音訊／影片預設格式、下載路徑）
   - 省流量模式（僅 Wi‑Fi 下載）
   - 自動繼續播放開關

---

## 五、非功能性需求

- **效能**
  - 播放切歌延遲 < 300ms（本機檔案）
  - 首次啟動時間 < 3 秒（不含資料庫冷啟）

- **穩定性**
  - 在背景播放 1 小時以上不出現明顯 memory leak / crash
  - 大量曲目（例如 5,000 首）時，媒體庫列表仍能流暢滾動

- **儲存與安全**
  - 下載檔案存在 App 專用目錄（避免被相簿亂入）
  - 不要求登入，不存敏感個資（初期版本）

---

## 六、後續可擴充方向（預留欄位）

- 匯出／匯入播放清單（JSON）
- 多裝置同步（你之後可以用自己後端＋帳號系統）
- 歌詞支援（LRC 檔解析）
- 定時關閉（睡眠模式）

---

如果你要，我可以下一步幫你把「資料表 schema（SQLite）」跟「主要 Dart class（MediaItem / Playlist / DownloadTask / PlayerState）」也一起定出來，變成可以直接開工的藍圖。

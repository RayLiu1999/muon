# Muon 專案教學 (2)：Drift 資料庫與 TDD 開發

這篇我們將了解 Muon 中最底層的「資料庫」是如何設計的，以及什麼是 TDD (測試驅動開發)。

---

## 1. Drift 架構快速了解

在 `lib/data/database/` 目錄下，你可以看到我們把資料庫拆成了三個部分：

1. **Tables (資料表定義)** `tables/`：
   這裡用 Dart 程式碼定義了 SQLite 的資料表結構。例如 `MediaItems` 表裡面有什麼欄位 (ID, title, path 等)。
2. **DAOs (Data Access Object)** `daos/`：
   資料表有了，但我們不希望每次都在 UI 裡寫 SQL 語法。DAO 的作用就是把「新增、刪除、修改、查詢」包裝成好呼叫的函式。
   例如 `MediaDao` 裡有一個 `getFavorites()` 函式，呼叫它就能拿到所有按了愛心的歌曲。

3. **AppDatabase** `app_database.dart`：
   這是整個資料庫的大腦，負責把所有的 Tables 和 DAOs 註冊進來，並且管理資料庫的版本更新 (Migration)。

> **什麼是 `.g.dart` 檔案？**
> 你會發現很多檔案旁邊都會有一個長得一樣，但多了 `.g` 的檔案（例如 `app_database.g.dart`）。
> 這些是 `build_runner` 自動產生的程式碼！我們只寫核心邏輯，剩下的繁瑣程式碼讓機器幫我們寫。**永遠不要去手動修改 `.g.dart` 檔案。**

---

## 2. 我們設計了哪些資料表？

為了滿足音樂播放器的需求，Muon 有 4 張核心資料表：

1. **MediaItems**：儲存所有的「歌曲」資訊（標題、長度、實體檔案路徑、是不是最愛）。
2. **Playlists**：儲存所有的「播放清單」資訊。我們預設建了三個無法刪除的系統清單（全部歌曲、最近下載、我的最愛），未來使用者還可以自己新增清單。
3. **PlaylistItems**：這是一張「關聯表」。一首歌可以出現在多個清單，一個清單可以有多首歌。這張表專門用來記錄「哪一首歌在那個清單的第幾個位置」。
4. **DownloadTasks**：記錄當前下載任務進度（等待中、下載中、完成、失敗）。

---

## 3. 什麼是 TDD (Test-Driven Development)？

「測試驅動開發」是我們開發 Muon 的核心原則。簡單來說就是：**先寫測試，再寫程式。**

在 `test/integration/database/` 資料夾下，我們為每一個 DAO 都寫了包含幾十個測試案例的檔案。

**為什麼要這樣做？**
身為新手，最怕的就是「改了 A 功能，壞了 B 功能，但自己沒發現」。
有了這些自動化測試，我們可以在幾秒鐘內驗證資料庫的「新增、查詢、刪除」是不是都還正常運作。這給了我們極大的信心來重構和優化程式碼。

### 測試是如何運作的？

在測試中，我們不會真的去寫入手機的儲存空間，而是建立一個 **in-memory (記憶體中) 的 SQLite 資料庫**。測試跑完，資料就清空了，不會留下痕跡，速度也非常快。

---

## 4. 實戰：從資料庫到 UI 的旅程

當你要在首頁顯示「我的最愛」時，這個資料是怎麼流動的？

1. **DAO 層 (`MediaDao`)**：有一段程式碼負責向資料庫要資料。
   ```dart
   Stream<List<MediaItem>> watchFavorites() => ...
   ```
2. **Repository 層 (`MediaRepository`)**：把 DAO 包裝起來，未來如果我們想加入「快取」，就會在這裡加，而不用動 DAO。
3. **Provider 層 (`media_provider.dart`)**：將 Repository 轉換成 Riverpod 狀態。
   ```dart
   @riverpod
   Stream<List<MediaItem>> favoriteMediaItems(Ref ref) {
     return ref.watch(mediaRepositoryProvider).watchFavorites();
   }
   ```
4. **UI 層 (`HomePage`)**：使用 `ref.watch(favoriteMediaItemsProvider)` 來監聽變化並畫出列表。只要使用者點擊愛心（修改了資料庫），這個 Stream 就會自動發送新資料，UI 就會瞬間自己更新！

**下一篇，我們將介紹最複雜的部分：AudioService 與背景播放的魔術！**

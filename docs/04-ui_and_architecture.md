# Muon 專案教學 (4)：UI 架構與 Riverpod 整合

App 寫到中期，最容易一團亂的就是 UI 程式碼。在 Muon 中，我們做了很多分離的設計，讓畫面不被複雜的邏輯綁架。

---

## 1. 路由系統：為什麼用 GoRouter？

以前在 Flutter 裡，換頁可能就是用 `Navigator.push(...)`。這樣寫雖然快，但在面對複雜的導航結構時會有很多問題：

- 深層連結 (Deep linking) 很難做。
- 帶底部導航列 (Bottom Navigation Bar) 的 App，你希望切換 Tag 時，裡面的捲動狀態不要消失。

我們選用 `go_router` 搭配它的 `StatefulShellRoute`。

在 `lib/app.dart` 中我們定義了路由：

- 根路徑會先進入 `AppShell`（一個有底部三個按鈕的空殼）。
- `AppShell` 的內容根據當前選中的 Tab 切換為：`HomePage` (首頁)、`SearchPage` (搜尋)、`SettingsPage` (設定)。

而且很重要的一點：**MiniPlayer (迷你播放器) 也放進了 AppShell 裡**。這樣不論你切換到哪個 Tab，MiniPlayer 都會固定浮在最下方！

---

## 2. 依賴注入 (Dependency Injection)

什麼是「依賴注入」？簡單來說就是：**不要在元件內部建立它需要的工具，而是從外面傳給它。**

例如：App 啟動時需要初始化剛學到的 `AppDatabase` 和 `AppAudioHandler`。

我們在 `main.dart` 裡的作法：

1. 啟動 `audio_service`，拿到 handler 實例。
2. 開啟本機檔案資料庫，拿到 database 實例。
3. 利用 Riverpod 的 **ProviderScope override** 魔法，把它們丟到全域的 Provider 裡。

```dart
// 在 main.dart
runApp(
  ProviderScope(
    overrides: [
      audioHandlerProvider.overrideWithValue(audioHandler),
      databaseProvider.overrideWithValue(database),
    ],
    child: const MuonApp(),
  ),
);
```

**這樣做有什麼好處？**
無敵好處！現在我們 App 裡的**任何**角落，只要透過 `ref.watch(databaseProvider)` 就可以拿到已經打開的資料庫。
而在寫測試碼時，我們可以把真正的資料庫 override 換成「測試用的假資料庫」，程式其他地方一行都不用改！

---

## 3. Mock 服務 (模擬資料)

身為新手，有時候後端 API 還沒好，或者拿不到 YouTube API Key。這時候能卡著不開發嗎？

不行！所以我們在 `lib/data/services/` 使用了 **Mock (模擬)** 的技巧。

針對「搜尋」和「下載」，我們分別建立了一個**介面 (Interface)**：

```dart
abstract class YouTubeSearchService {
  Future<List<SearchResult>> search(String query);
}
```

目前這個介面後面的實作是 `MockYouTubeSearchService`。它會故意暫停個 800 毫秒（模擬網路延遲），然後吐出一堆叫做 "測試頻道"、"相關影片 1" 的假資料。

而下載服務 `MockDownloadService` 更絕，它會自己每 300 毫秒更新一次假進度 (10%, 20%...) 然後寫入漂漂亮亮的資料到 Drift 資料庫裡。

**這給我們的好處：**

- UI 開發不會被卡住，這就是為什麼我們現在已經能畫出完整的搜尋頁、載入框、進度條！
- 未來真正的後端 API 寫好後，只要新增一個 `RealYouTubeSearchService`，並去 Provider 裡換掉那行 return 程式碼就好，UI 完全不用動。

---

## 4. 接下來的旅程

目前我們完成了：
✅ 專案初期設定、主題、資料庫、DAO
✅ 音訊背景播放、MiniPlayer、FullScreenPlayer
✅ Mock 的搜尋與下載服務、媒體庫首頁

**下一篇，我們將深入後端的世界：FastAPI + yt-dlp 是如何驅動 Muon 的搜尋與下載功能的！**

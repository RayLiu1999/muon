# Muon 專案教學 (5)：後端服務 — FastAPI + yt-dlp

前四篇我們已經建好了前端 App 的骨架，包括資料庫、音訊播放和 UI。但 Muon 的核心價值 —— 「搜尋 YouTube 並下載音樂」 —— 完全依賴於一個獨立的後端服務。

---

## 1. 為什麼需要後端？

你可能會想：「Flutter 不能直接呼叫 YouTube API 嗎？」

技術上可以，但有幾個致命問題：

1. **YouTube 不提供直接下載 API**：官方 API 只能取得影片**資訊**，不能取得**下載連結**。
2. **yt-dlp 是 Python 工具**：它是一個強大的命令列工具，能解析 YouTube 的加密串流並取得真正的媒體檔案，但它無法直接在手機上運行。
3. **避免 App 被下架風險**：把下載邏輯放在後端伺服器上，App 本身只是一個「播放器」，降低了法律風險。

所以我們的架構是：

```text
[Flutter App] --HTTP--> [FastAPI 後端] --yt-dlp--> [YouTube]
     ↑                       |
     └── 下載完成的 .m4a 檔案 ──┘
```

---

## 2. 後端技術棧

| 元件           | 用途                                                    |
| -------------- | ------------------------------------------------------- |
| **FastAPI**    | Python 的現代 Web 框架，支援非同步、自動生成 API 文件   |
| **yt-dlp**     | YouTube 影片/音訊解析與下載的核心引擎                   |
| **yt-dlp-ejs** | yt-dlp 的伴隨套件，包含解碼 YouTube JS Challenge 的腳本 |
| **Node.js**    | 執行 yt-dlp-ejs 腳本所需的 JavaScript Runtime           |
| **FFmpeg**     | 音訊/影片格式轉換（確保 iOS 相容的 H.264 + AAC 編碼）   |
| **Docker**     | 容器化部署，確保環境一致性                              |

---

## 3. 後端的資料夾結構

```text
backend/
├── app/
│   ├── main.py              # FastAPI 應用程式入口
│   ├── api/
│   │   └── endpoints/
│   │       ├── search.py    # 搜尋 API 端點
│   │       ├── download.py  # 下載 API 端點
│   │       └── status.py    # 下載狀態查詢端點
│   ├── models/              # Pydantic 資料模型
│   └── services/
│       ├── youtube.py       # yt-dlp 搜尋邏輯
│       └── downloader.py    # yt-dlp 背景下載邏輯
├── downloads/               # (執行時生成) 下載完成的媒體檔案
├── Dockerfile               # Docker 映像定義
├── docker-compose.yml       # Docker Compose 設定
├── requirements.txt         # Python 依賴列表
└── .env.example             # 環境變數範本
```

---

## 4. 三大 API 端點

### 4.1 搜尋 API — `GET /api/search`

**功能**：接收關鍵字，透過 yt-dlp 搜尋 YouTube，回傳影片清單。

```python
# app/services/youtube.py (簡化版)
def search_youtube(query: str, page: int = 1, limit: int = 20):
    ydl_opts = {
        'extract_flat': 'in_playlist',  # 只抓基本資訊，不深度解析
        'quiet': True,
        'default_search': 'ytsearch',
        'js_runtimes': {'node': {}},    # 啟用 Node.js JS Runtime
    }
    # 如果有 cookies.txt，帶上以繞過 bot 驗證
    if os.path.isfile("cookies.txt"):
        ydl_opts['cookiefile'] = "cookies.txt"

    total_needed = page * limit
    search_query = f"ytsearch{total_needed}:{query}"

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(search_query, download=False)
        # ... 解析並回傳結果
```

**重點**：`extract_flat` 模式會跳過深度格式解析，讓搜尋速度快很多。

### 4.2 下載 API — `POST /api/download`

**功能**：接收 YouTube video ID，在背景啟動下載任務。

```python
# 音訊下載的 yt-dlp 設定
ydl_opts = {
    'format': 'bestaudio/best',
    'postprocessors': [{
        'key': 'FFmpegExtractAudio',
        'preferredcodec': 'm4a',       # iOS 原生支援的格式
        'preferredquality': '192',
    }],
    'postprocessor_args': {
        'ExtractAudio': ['-acodec', 'aac', '-movflags', '+faststart'],
    },
}
```

**為什麼用 AAC + faststart？**

- **AAC**：是 iOS `AVPlayer` 原生支援的音訊編碼，不需要額外解碼器。
- **faststart**：把 MP4 的 metadata (moov atom) 移到檔案開頭，讓串流播放時不需要下載整個檔案就能開始播放。

### 4.3 狀態 API — `GET /api/download/{task_id}/status`

**功能**：回傳指定任務的下載進度（0~100%）、狀態（queued/downloading/completed/error）。

前端每 1 秒輪詢一次這個 API，更新下載進度條的百分比。

---

## 5. 前端如何串接？

在 Flutter 端，我們用 `http` 套件呼叫後端 API：

```dart
// lib/data/services/real_youtube_search_service.dart (簡化版)
class RealYouTubeSearchService implements YouTubeSearchService {
  final String apiUrl;  // 透過 --dart-define=API_URL=... 傳入

  @override
  Future<List<SearchResult>> search(String query) async {
    final response = await http.get(
      Uri.parse('$apiUrl/api/search?query=$query'),
    );
    // 解析 JSON 回傳搜尋結果...
  }
}
```

啟動 App 時，透過環境變數指定後端位址：

```bash
flutter run --dart-define=API_URL=http://192.168.50.35:8000
```

---

## 6. 後端本機開發

如果你想在本機開發，最簡單的方式是 Docker Compose：

```bash
cd backend
cp .env.example .env
# 編輯 .env 設定你的本機 IP
docker compose up -d --build
```

服務啟動後，可以在 `http://localhost:8000/docs` 看到自動生成的 Swagger API 文件，直接在瀏覽器上測試每個 API！

---

**下一篇，我們將分享把 Muon 部署到線上 VPS 時遇到的所有坑，以及如何一一解決！**

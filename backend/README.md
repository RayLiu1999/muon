# Muon Backend Service 🚀

本目錄包含了 Muon 點唱機應用的後端服務。它採用 **Python + FastAPI** 撰寫，負責處理解析 YouTube 搜尋、取得影片資訊，並在背景將音訊/影片下載至伺服器供前端存取。

## 🎯 核心功能

- **Search API (`/api/search`)**：串接 [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) 直接查詢 YouTube 並解析搜尋結果的標題、頻道、縮圖、長度。
- **Download API (`/api/download`)**：提供背景下載。不僅支援純音軌（預設 m4a），也能強制抽出 iOS 完美相容的 H.264 影片（封裝為 mp4+aac）。
- **Status API (`/api/status/{task_id}`)**：提供前端定期輪詢下載進度用的非同步狀態回應。
- **靜態檔案伺服 (`/downloads`)**：利用 FastAPI 的 `StaticFiles` 以串流模式提供實體檔案，讓前端可以直接撥放音樂。
- **背景任務與清理**：提供基於時間的 TTL (Time-To-Live) 快取清理服務，維護系統磁碟空間。

## ⚙️ 環境配置

強烈建議採用 **Docker Compose** 做本機開發或部署。我們已經配置好了完整的容器化流程。

### 使用 Docker (📦 推薦方式)

1. 先複製環境變數範本並修改成你機器的 IP：
   ```bash
   cp .env.example .env
   # 編輯 .env，將 HOST_IP 改成你電腦區域網路的 IPv4 網址 (如 192.168.50.35)
   ```
2. 使用 Docker Compose 直接啟動（含自動構建）：
   ```bash
   docker compose up -d --build
   ```

服務將啟動在 `http://${HOST_IP}:8000` (如果沒有設置則預設為 127.0.0.1:8000)。
API 文件 (Swagger UI) 可以在 `http://${HOST_IP}:8000/docs` 查看並直接測試！

---

### 原生 Python (🐍 開發模式)

如果你需要直接偵錯 Python 原始碼，你可以使用 `uvicorn` 直接執行：

1. **建立虛擬環境**：

   ```bash
   python -m venv venv
   source venv/bin/activate  # Windows 則是 `venv\Scripts\activate`
   ```

2. **安裝依賴套件 (同時必須確認有安裝 ffmpeg)**：
   本系統高度仰賴 `ffmpeg` 針對音訊轉檔。請確保你的主機已安裝 ffmpeg！

   ```bash
   pip install -r requirements.txt
   ```

3. **啟動 FastAPI 服務**：
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

## 📂 資料夾結構

- `/app`：核心應用程式碼。
  - `main.py`：FastAPI 掛載點、中介軟體和路由引入。
  - `api.py`：搜尋、下載及狀態等核心路由邏輯。
  - `services/`：獨立了 `downloader.py` 背景下載服務與進度勾點。
  - `models/`：純資料的 Pydantic 定義。
- `/downloads`：(執行時生成) 預設存放解析完畢之 mp4/m4a 播放檔的實體路徑。
- `.env`：Docker Compose 指定 Host IP 使用的最基礎設定檔。

## 🔧 維護注意事項

- `yt-dlp` 更新頻繁。若 Youtube 更改介面導致下載中斷或搜尋找不到結果，請直接在容器或主機執行 `pip install -U yt-dlp` 進行升級。
- 若 iOS App 切換到全螢幕模式後**螢幕黑屏只有聲音**，即代表 ffmpeg 轉換格式脫離了 AVC(H.264) + AAC 的規範，請修改 `app/services/downloader.py` 中相對應的 `postprocessor_args` 參數並重新 build Docker 影像。

# Muon 專案教學 (6)：Docker 部署與 YouTube 問題排除

把 Muon 後端部署到雲端 VPS 時，我們踩過了無數的坑。這篇文章完整記錄了所有問題與解法，是實戰中最寶貴的經驗。

---

## 1. Docker 容器化

### 1.1 Dockerfile 設計

Muon 後端的 Dockerfile 基於 `python:3.13-slim`（精簡映像），安裝了以下系統依賴：

| 依賴     | 用途                                            |
| -------- | ----------------------------------------------- |
| `ffmpeg` | yt-dlp 下載後的音訊/影片格式轉換                |
| `curl`   | 容器健康檢查                                    |
| `nodejs` | yt-dlp 解碼 YouTube JS Challenge 的必要 Runtime |

Python 套件方面，關鍵是使用 `yt-dlp[default]` 而非單純的 `yt-dlp`：

```dockerfile
RUN pip install --no-cache-dir "yt-dlp[default]"
```

`[default]` 會自動安裝 `yt-dlp-ejs` 這個伴隨套件，裡面包含了解碼 YouTube JavaScript Challenge 的腳本。**少了這個套件，yt-dlp 就算有 Node.js 也無法正常取得影片格式。**

### 1.2 安全性設計

容器內以非 root 使用者 `appuser` 執行應用程式：

```dockerfile
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app
USER appuser
```

---

## 2. YouTube Bot 驗證阻擋

### 2.1 問題描述

部署到雲端 VPS 後，yt-dlp 立刻報錯：

```
ERROR: Sign in to confirm you're not a bot.
```

**根本原因**：YouTube 會對機房 IP（特別是 OVH、AWS、GCP 等常見的雲端供應商）進行更嚴格的機器人驗證。住家網路通常不會遇到這個問題。

### 2.2 解決方案：使用 Cookies

我們嘗試了兩種方案：

| 方案                                                                 | 效果                                     |
| -------------------------------------------------------------------- | ---------------------------------------- |
| `extractor_args: {'youtube': {'player_client': ['android', 'web']}}` | ❌ OVH 的 IP 太新，Android client 也被擋 |
| 帶入瀏覽器的 `cookies.txt`                                           | ✅ 成功繞過                              |

#### 如何取得 cookies.txt

**推薦方式：使用 yt-dlp 命令列（最穩定）**

```bash
# 從你平常看 YouTube 的電腦執行
yt-dlp --cookies-from-browser chrome --cookies cookies.txt "https://www.youtube.com"
```

> **⚠️ 安全提醒**：建議建立一個專用的瀏覽器 Profile 或 Google 帳號，避免匯出包含其他網站登入資訊的 cookies。

#### Cookies 的有效期

| 情況                  | 預估有效期 |
| --------------------- | ---------- |
| 正常使用              | 2～4 個月  |
| Google 偵測到異常登入 | 立即失效   |
| 手動登出 Google       | 立即失效   |

失效時重新匯出一份即可。好消息是，yt-dlp 會自動回寫更新後的 cookies 以延長有效期。

### 2.3 Docker 中的 Cookies 掛載

在 `docker-compose.yml` 中，透過環境變數設定 cookies 路徑：

```yaml
services:
  muon-backend:
    volumes:
      - ${COOKIES_PATH:-./cookies.txt}:/app/cookies.txt
```

> **注意**：不能使用 `:ro`（唯讀）掛載！yt-dlp 在使用 cookies 後會自動將 YouTube 回傳的新 cookies 寫回檔案，以延長 session 有效期。如果設為唯讀，yt-dlp 會在關閉時報 `OSError: Read-only file system` 錯誤。

在 Portainer 的 Stack 環境變數中設定 `COOKIES_PATH` 指向 VPS 上的實際路徑即可。

---

## 3. YouTube JS Challenge 解碼失敗

### 3.1 問題描述

Bot 驗證通過後，又遇到了新的錯誤：

```
WARNING: Signature solving failed: Ensure you have a supported JavaScript runtime
         and challenge solver script distribution installed.
WARNING: Only images are available for download.
```

這意味著 yt-dlp 只能拿到影片的縮圖（storyboard），完全無法取得影片或音訊的下載連結。

### 3.2 根本原因（三個缺失元件）

YouTube 現在使用 JavaScript Challenge 來保護影片的下載連結。yt-dlp 需要**三個東西**才能成功解碼：

| #   | 元件                     | 用途                     | 安裝方式                        |
| --- | ------------------------ | ------------------------ | ------------------------------- |
| 1   | **Node.js**              | JavaScript 執行環境      | `apt-get install nodejs`        |
| 2   | **yt-dlp-ejs**           | Challenge Solver 腳本    | `pip install "yt-dlp[default]"` |
| 3   | **`--js-runtimes node`** | 手動啟用 Node.js Runtime | 設定檔或程式碼參數              |

第三點是最容易被忽略的：**yt-dlp 預設只啟用 Deno 作為 JS Runtime，Node.js 必須手動啟用。**

### 3.3 CLI vs Python API 的差異

這裡有一個非常重要的陷阱：

| 使用方式                        | 是否讀取 config 檔                  |
| ------------------------------- | ----------------------------------- |
| `yt-dlp` 命令列                 | ✅ 會讀取 `~/.config/yt-dlp/config` |
| Python `yt_dlp.YoutubeDL(opts)` | ❌ **不會**讀取 config 檔           |

也就是說，即使你在容器的 config 檔寫了 `--js-runtimes node`，從命令列測試 `yt-dlp --list-formats` 一切正常，但 **FastAPI 透過 Python API 呼叫時仍然會失敗**！

**解法**：必須在 Python 程式碼的 `ydl_opts` 字典中明確指定：

```python
ydl_opts = {
    'format': 'bestaudio/best',
    'js_runtimes': {'node': {}},  # 注意：Python API 用 dict 格式，不是字串！
    # ...
}
```

> **格式陷阱**：CLI 用字串 `'node'`，但 Python API 要用 dict `{'node': {}}`。如果傳字串會報 `ValueError: Invalid js_runtimes format, expected a dict of {runtime: {config}}`。

---

## 4. iOS 相容性問題

### 4.1 影片黑屏只有聲音

如果 iOS App 播放影片時出現黑屏但有聲音，代表 FFmpeg 轉換時沒有產出正確的編碼格式。

**解法**：確保影片使用 H.264 (AVC) + AAC 編碼：

```python
'postprocessor_args': {
    'VideoConvertor': ['-c:v', 'libx264', '-c:a', 'aac', '-movflags', '+faststart'],
},
```

### 4.2 格式不可用 (Requested format is not available)

某些影片（如直播存檔、年代久遠的影片）可能沒有標準的 m4a 音軌或 MP4 影像。

**解法**：在 format 字串中加入多層容錯：

```python
# 影片：先找 H264+M4A，退而求其次找任何 MP4，再找所有格式讓 ffmpeg 轉
'format': 'bestvideo[vcodec^=avc1][ext=mp4]+bestaudio[ext=m4a]/bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'

# 音訊：找不到獨立音軌就下載整份影片再由 ffmpeg 提取
'format': 'bestaudio/best'
```

---

## 5. 部署檢查清單

當你要將 Muon 後端部署到新的 VPS 時，請依照以下順序確認：

- [ ] Docker 和 Docker Compose 已安裝
- [ ] `cookies.txt` 已上傳到 VPS 並設定正確路徑
- [ ] `docker-compose.yml` 中的 `COOKIES_PATH` 環境變數指向正確位置
- [ ] **不要**用 `:ro` 掛載 cookies（yt-dlp 需要回寫）
- [ ] Docker Build 時確認 `nodejs` 和 `yt-dlp[default]` 已安裝
- [ ] 進入容器驗證 `yt-dlp --verbose --list-formats "任意 YouTube 網址"` 能看到完整格式列表
- [ ] 確認 verbose 輸出中 `JS runtimes` 顯示為 `node` 而非 `none`

### 快速驗證指令

```bash
# 進入容器
docker exec -it <容器名稱> bash

# 確認 Node.js 版本
node --version

# 確認 yt-dlp-ejs 已安裝
pip list | grep yt-dlp

# 完整測試（應該能看到音訊和影片格式，不是只有 storyboard）
yt-dlp --verbose --cookies /app/cookies.txt --list-formats "https://www.youtube.com/watch?v=dQw4w9WgXcQ" 2>&1 | head -20
```

---

## 6. 問題排除速查表

| 錯誤訊息                                        | 原因                        | 解法                                                       |
| ----------------------------------------------- | --------------------------- | ---------------------------------------------------------- |
| `Sign in to confirm you're not a bot`           | VPS IP 被 YouTube 阻擋      | 使用 `cookies.txt`                                         |
| `OSError: Read-only file system: 'cookies.txt'` | cookies 掛載為唯讀          | 移除 docker-compose 中的 `:ro`                             |
| `Signature solving failed`                      | 缺少 JS Runtime 或 EJS 腳本 | 安裝 `nodejs` + `yt-dlp[default]`                          |
| `JS runtimes: none`                             | Node.js 未被 yt-dlp 啟用    | 加入 `--js-runtimes node` 或 `'js_runtimes': {'node': {}}` |
| `Invalid js_runtimes format`                    | Python API 格式錯誤         | 用 `{'node': {}}` 取代 `'node'`                            |
| `Requested format is not available`             | 影片格式特殊                | 在 format 字串加入更多降級選項                             |
| `Only images are available`                     | JS Challenge 解碼完全失敗   | 同時確認上述三個元件都已準備                               |

---

**恭喜你讀完了全部六篇教學！現在你已經完整了解了 Muon 從前端到後端、從開發到部署的所有細節。如果你也想打造自己的音樂播放器，這些經驗將會是你最好的起點。🎵**

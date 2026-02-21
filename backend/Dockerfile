# ————————————————————————————————
# Base：使用官方 Python slim 映像（符合 VPS 輕量需求）
# ————————————————————————————————
FROM python:3.13-slim

# 設定工作目錄
WORKDIR /app

# 安裝系統依賴
# - ffmpeg：yt-dlp 後處理（音訊格式轉換）所需
# - curl：健康檢查用
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg curl && \
    rm -rf /var/lib/apt/lists/*

# 先複製 requirements，利用 Docker layer cache 加速重複 build
COPY requirements.txt .

# 安裝 Python 套件（排除測試相關套件）
RUN pip install --no-cache-dir \
    fastapi \
    "uvicorn[standard]" \
    pydantic \
    yt-dlp \
    httpx

# 複製應用程式原始碼
COPY app/ ./app/

# 建立 downloads 目錄（容器內暫存下載檔案用）
RUN mkdir -p downloads

# 建立非 root 使用者，提高安全性
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app
USER appuser

# 對外開放 8000 port
EXPOSE 8000

# 健康檢查：定期 ping 根路徑
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# 啟動指令（生產環境建議加 --workers 數量，依 VPS CPU 調整）
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

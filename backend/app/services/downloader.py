import asyncio
import os
import uuid
import yt_dlp
from typing import Dict, Any

# 簡單的記憶體狀態管理（實際產品應放 Redis 或可持久化資料庫）
# 儲存格式: { task_id: {"status": "downloading", "progress": 0.5, "file_path": "..."}, ... }
download_tasks: Dict[str, Dict[str, Any]] = {}

DOWNLOAD_DIR = "downloads"
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

class MyLogger(object):
    def debug(self, msg):
        pass

    def warning(self, msg):
        pass

    def error(self, msg):
        print(f"yt-dlp Error: {msg}")

def yt_dlp_progress_hook(d, task_id):
    if d['status'] == 'downloading':
        total_bytes = d.get('total_bytes') or d.get('total_bytes_estimate')
        downloaded_bytes = d.get('downloaded_bytes', 0)
        if total_bytes:
            progress = downloaded_bytes / total_bytes
            download_tasks[task_id]["progress"] = progress
            download_tasks[task_id]["status"] = "downloading"
            
    elif d['status'] == 'finished':
        # yt-dlp 將副檔名轉換後（如果有後處理），檔名可能會變
        # 我們在這邊先標註 99%，等待 post-processor 完成後再透過例外處理或外部更新為 completed
        download_tasks[task_id]["progress"] = 0.99
        download_tasks[task_id]["status"] = "processing"

def download_audio_sync(source_id: str, task_id: str, quality: str = "best", audio_format: str = "m4a"):
    """
    同步執行 yt_dlp 的函式，應該要被放到 thread pool 裡執行
    """
    download_tasks[task_id] = {
        "source_id": source_id,
        "status": "queued",
        "progress": 0.0,
        "file_path": None,
        "error": None
    }
    
    if audio_format == "mp4":
        ydl_opts = {
            'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
            'outtmpl': os.path.join(DOWNLOAD_DIR, f"{task_id}.%(ext)s"),
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'm4a',
                'preferredquality': '192',
            }],
            'keepvideo': True,
            'logger': MyLogger(),
            'progress_hooks': [lambda d: yt_dlp_progress_hook(d, task_id)],
            'quiet': True,
        }
    else:
        # 下載存音訊邏輯
        yt_quality = "bestaudio/best" if quality == "best" else "worstaudio/worst"
        bitrate = '192' if quality == "best" else '96'
        ydl_opts = {
            'format': f'{audio_format}/{yt_quality}',
            'outtmpl': os.path.join(DOWNLOAD_DIR, f"{task_id}.%(ext)s"),
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': audio_format,
                'preferredquality': bitrate,
            }],
            'logger': MyLogger(),
            'progress_hooks': [lambda d: yt_dlp_progress_hook(d, task_id)],
            'quiet': True,
        }

    try:
        download_tasks[task_id]["status"] = "downloading"
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            # 觸發下載
            # 注意：這裡使用 YouTube URL 格式
            url = f"https://www.youtube.com/watch?v={source_id}"
            
            # 抽出最終的檔名：
            info = ydl.extract_info(url, download=True)
            # 拿到預期輸出的檔案路徑（經過 FFmpeg 後可能會改變附檔名，如果沒 FFmpeg，它會保留原來附檔名）
            # 因為我們指定了 codec，最後檔案通常是 {task_id}.{audio_format}
            expected_filename = os.path.join(DOWNLOAD_DIR, f"{task_id}.{audio_format}")
            
            if os.path.exists(expected_filename):
                download_tasks[task_id]["file_path"] = expected_filename
            else:
                # 備用：利用 ydl.prepare_filename
                base = ydl.prepare_filename(info)
                name, _ = os.path.splitext(base)
                download_tasks[task_id]["file_path"] = f"{name}.{audio_format}"

        download_tasks[task_id]["status"] = "completed"
        download_tasks[task_id]["progress"] = 1.0

    except Exception as e:
        download_tasks[task_id]["status"] = "failed"
        download_tasks[task_id]["error"] = str(e)

async def start_background_download(source_id: str, task_id: str, quality: str = "best", audio_format: str = "m4a"):
    """
    使用 asyncio.to_thread 讓同步的 yt_dlp 在背景線程執行，不會卡住 FastAPI
    """
    await asyncio.to_thread(download_audio_sync, source_id, task_id, quality, audio_format)

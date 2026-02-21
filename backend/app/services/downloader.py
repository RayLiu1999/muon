import asyncio
import os
import time
import yt_dlp
from typing import Dict, Any

# 簡單的記憶體狀態管理（實際產品應放 Redis 或可持久化資料庫）
# 儲存格式: { task_id: {"status": ..., "progress": ..., "file_path": ..., "created_at": ...} }
download_tasks: Dict[str, Dict[str, Any]] = {}

DOWNLOAD_DIR = "downloads"
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

# 方案②：定期 TTL 清理設定
TASK_TTL_SECONDS = 600      # 任務記錄保留 10 分鐘
FILE_TTL_SECONDS = 600      # 未被取走的檔案保留 10 分鐘
CLEANUP_INTERVAL_SECONDS = 120  # 每 2 分鐘掃描一次


class MyLogger(object):
    def debug(self, msg: str) -> None:
        pass

    def warning(self, msg: str) -> None:
        pass

    def error(self, msg: str) -> None:
        print(f"yt-dlp Error: {msg}")


def yt_dlp_progress_hook(d: Dict[str, Any], task_id: str) -> None:
    if d['status'] == 'downloading':
        total_bytes = d.get('total_bytes') or d.get('total_bytes_estimate')
        downloaded_bytes = d.get('downloaded_bytes', 0)
        if total_bytes:
            progress = downloaded_bytes / total_bytes
            download_tasks[task_id]["progress"] = progress
            download_tasks[task_id]["status"] = "downloading"

    elif d['status'] == 'finished':
        # yt-dlp 將副檔名轉換後（如果有後處理），檔名可能會變
        # 先標註 99%，等待 post-processor 完成
        download_tasks[task_id]["progress"] = 0.99
        download_tasks[task_id]["status"] = "processing"


def download_audio_sync(source_id: str, task_id: str, quality: str = "best", audio_format: str = "m4a") -> None:
    """
    同步執行 yt_dlp 的函式，應該要被放到 thread pool 裡執行
    """
    download_tasks[task_id] = {
        "source_id": source_id,
        "status": "queued",
        "progress": 0.0,
        "file_path": None,
        "error": None,
        "created_at": time.time(),  # 記錄建立時間，供 TTL 清理使用
    }

    if audio_format == "mp4":
        # iOS 的 AVPlayer 預設只支援 H.264 (avc1) 硬體解碼。
        # 限定 yt-dlp 抓取 h264 影像與 m4a 音軌，或者強制轉換成 mp4+aac。
        ydl_opts = {
            'format': 'bestvideo[vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4]/best',
            'outtmpl': os.path.join(DOWNLOAD_DIR, f"{task_id}.%(ext)s"),
            'merge_output_format': 'mp4',
            'postprocessors': [{
                'key': 'FFmpegVideoConvertor',
                'preferedformat': 'mp4',
            }],
            'postprocessor_args': {
                # 確保影片使用 h264 和 aac 編碼，加上 faststart 以支援串流播放
                'VideoConvertor': ['-c:v', 'libx264', '-c:a', 'aac', '-movflags', '+faststart'],
            },
            'keepvideo': False, # 因為已經合併，不需要保留原始影片檔
            'logger': MyLogger(),
            'progress_hooks': [lambda d: yt_dlp_progress_hook(d, task_id)],
            'quiet': True,
        }
    else:
        # 下載純音訊邏輯
        yt_quality = "bestaudio/best" if quality == "best" else "worstaudio/worst"
        bitrate = '192' if quality == "best" else '96'
        ydl_opts = {
            'format': yt_quality,
            'outtmpl': os.path.join(DOWNLOAD_DIR, f"{task_id}.%(ext)s"),
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': audio_format,
                'preferredquality': bitrate,
            }],
            # 強制 FFmpeg 使用 AAC-LC 編碼器，確保 iOS AVPlayer 相容
            'postprocessor_args': {
                'ExtractAudio': ['-acodec', 'aac', '-movflags', '+faststart'],
            },
            'logger': MyLogger(),
            'progress_hooks': [lambda d: yt_dlp_progress_hook(d, task_id)],
            'quiet': True,
        }

    try:
        download_tasks[task_id]["status"] = "downloading"
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            url = f"https://www.youtube.com/watch?v={source_id}"
            info = ydl.extract_info(url, download=True)
            expected_filename = os.path.join(DOWNLOAD_DIR, f"{task_id}.{audio_format}")

            if os.path.exists(expected_filename):
                download_tasks[task_id]["file_path"] = expected_filename
            else:
                base = ydl.prepare_filename(info)
                name, _ = os.path.splitext(base)
                download_tasks[task_id]["file_path"] = f"{name}.{audio_format}"

        download_tasks[task_id]["status"] = "completed"
        download_tasks[task_id]["progress"] = 1.0

    except Exception as e:
        download_tasks[task_id]["status"] = "failed"
        download_tasks[task_id]["error"] = str(e)


async def start_background_download(source_id: str, task_id: str, quality: str = "best", audio_format: str = "m4a") -> None:
    """
    使用 asyncio.to_thread 讓同步的 yt_dlp 在背景線程執行，不會卡住 FastAPI
    """
    await asyncio.to_thread(download_audio_sync, source_id, task_id, quality, audio_format)


def _delete_task_files(task_id: str) -> None:
    """
    刪除與 task_id 對應的所有實體檔案（包含 .mp4 和對應音訊）
    """
    task = download_tasks.get(task_id)
    if not task:
        return

    file_path = task.get("file_path")
    if file_path and os.path.exists(file_path):
        os.remove(file_path)
        print(f"[cleanup] 已刪除檔案: {file_path}")

    # 同時清除可能存在的配對檔（例如 mp4 下載同時產生 m4a）
    if file_path:
        base, ext = os.path.splitext(file_path)
        companion_exts = ['.mp4', '.m4a', '.mp3', '.webm']
        for companion_ext in companion_exts:
            if companion_ext == ext:
                continue
            companion = f"{base}{companion_ext}"
            if os.path.exists(companion):
                os.remove(companion)
                print(f"[cleanup] 已刪除配對檔: {companion}")


def cleanup_task_after_transfer(task_id: str) -> None:
    """
    方案①：傳輸完成後立即清理檔案與任務記錄。
    應由 download.py 的 BackgroundTasks 在 FileResponse 後呼叫。
    """
    _delete_task_files(task_id)
    if task_id in download_tasks:
        del download_tasks[task_id]
        print(f"[cleanup] 已移除任務記錄: {task_id}")


async def periodic_cleanup() -> None:
    """
    方案②：定期掃描清理超時的任務記錄與殘留檔案，作為防護網。
    應於 FastAPI lifespan 中作為背景 task 持續執行。
    """
    while True:
        await asyncio.sleep(CLEANUP_INTERVAL_SECONDS)
        now = time.time()
        expired_task_ids = [
            tid for tid, task in list(download_tasks.items())
            if now - task.get("created_at", now) > TASK_TTL_SECONDS
        ]

        for task_id in expired_task_ids:
            print(f"[cleanup] TTL 到期，清理任務: {task_id}")
            _delete_task_files(task_id)
            download_tasks.pop(task_id, None)

        # 額外掃描 downloads/ 目錄中所有孤兒檔案（沒有對應任務記錄）
        try:
            for filename in os.listdir(DOWNLOAD_DIR):
                filepath = os.path.join(DOWNLOAD_DIR, filename)
                if not os.path.isfile(filepath):
                    continue
                file_age = now - os.path.getmtime(filepath)
                if file_age > FILE_TTL_SECONDS:
                    os.remove(filepath)
                    print(f"[cleanup] 掃描刪除孤兒檔案: {filepath}")
        except OSError as e:
            print(f"[cleanup] 掃描目錄時發生錯誤: {e}")

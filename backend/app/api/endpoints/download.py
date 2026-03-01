import os
import uuid
from fastapi import APIRouter, BackgroundTasks, HTTPException, Query, Request
from fastapi.responses import FileResponse
from pydantic import BaseModel
from app.services.downloader import (
    start_background_download,
    download_tasks,
    cleanup_task_after_transfer,
)
from app.core.security import limiter

router = APIRouter()


class DownloadRequest(BaseModel):
    source_id: str
    title: str
    thumbnail_url: str = ""
    quality: str = "best"
    format: str = "m4a"


@router.post("/download")
@limiter.limit("10/minute")
async def request_download(request: Request, req: DownloadRequest, background_tasks: BackgroundTasks):
    """
    接收前端下載請求，將任務丟入背景執行，並回傳任務 ID。
    """
    task_id = str(uuid.uuid4())

    # 建立初始狀態
    download_tasks[task_id] = {
        "source_id": req.source_id,
        "status": "queued",
        "progress": 0.0,
        "file_path": None,
        "error": None
    }

    # 加入背景任務
    background_tasks.add_task(
        start_background_download, req.source_id, task_id, req.quality, req.format
    )

    return {"task_id": task_id, "status": "queued"}


@router.get("/download/{task_id}/status")
@limiter.limit("60/minute")
def get_download_status(request: Request, task_id: str):
    """
    前端輪詢此 API 以取得最新進度與狀態。
    """
    if task_id not in download_tasks:
        raise HTTPException(status_code=404, detail="Task not found")

    return download_tasks[task_id]


@router.get("/thumbnail/{task_id}")
@limiter.limit("20/minute")
def get_thumbnail(request: Request, task_id: str):
    """
    返回任務對應的本地高畫質縮圖。
    不觸發 cleanup，供前端在下載音訊前先取結。
    """
    if task_id not in download_tasks:
        raise HTTPException(status_code=404, detail="Task not found")

    thumb_path = download_tasks[task_id].get("thumbnail_path")
    if not thumb_path or not os.path.exists(thumb_path):
        raise HTTPException(status_code=404, detail="Thumbnail not available")

    return FileResponse(path=thumb_path, media_type="image/jpeg")


@router.get("/file/{task_id}")
@limiter.limit("10/minute")
def get_downloaded_file(
    request: Request,
    task_id: str,
    background_tasks: BackgroundTasks,
    ext: str = Query(None),
):
    """
    當進度 100% 後，前端調用此 API 取得實體檔案。
    傳輸完成後，方案①：立即在背景刪除該檔案與任務記錄（cleanup_task_after_transfer）。
    """
    if task_id not in download_tasks:
        raise HTTPException(status_code=404, detail="Task not found")

    task = download_tasks[task_id]

    if task["status"] != "completed" or task["file_path"] is None:
        raise HTTPException(status_code=400, detail="File is not ready yet")

    target_path = task["file_path"]
    if ext:
        base, _ = os.path.splitext(target_path)
        target_path = f"{base}.{ext}"

    if not os.path.exists(target_path):
        raise HTTPException(status_code=404, detail="File not found on disk")

    file_ext = os.path.splitext(target_path)[1]

    # 方案①：FileResponse 串流完畢後，由 BackgroundTasks 執行立即清理
    background_tasks.add_task(cleanup_task_after_transfer, task_id)

    return FileResponse(
        path=target_path,
        media_type=(
            "video/mp4" if file_ext == ".mp4"
            else ("audio/mpeg" if file_ext == ".mp3" else "audio/mp4")
        ),
        filename=f"{task['source_id']}{file_ext}",
    )

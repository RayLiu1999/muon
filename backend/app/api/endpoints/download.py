import uuid
import os
from fastapi import APIRouter, BackgroundTasks, HTTPException
from pydantic import BaseModel
from fastapi.responses import FileResponse
from app.services.downloader import start_background_download, download_tasks

router = APIRouter()

class DownloadRequest(BaseModel):
    source_id: str
    title: str
    thumbnail_url: str = ""

@router.post("/download")
async def request_download(req: DownloadRequest, background_tasks: BackgroundTasks):
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
    background_tasks.add_task(start_background_download, req.source_id, task_id)
    
    return {"task_id": task_id, "status": "queued"}

@router.get("/download/{task_id}/status")
def get_download_status(task_id: str):
    """
    前端輪詢此 API 以取得最新進度與狀態。
    """
    if task_id not in download_tasks:
        raise HTTPException(status_code=404, detail="Task not found")
        
    return download_tasks[task_id]

@router.get("/file/{task_id}")
def get_downloaded_file(task_id: str):
    """
    當進度 100% 後，前端調用此 API 取得實體音檔。
    """
    if task_id not in download_tasks:
        raise HTTPException(status_code=404, detail="Task not found")
        
    task = download_tasks[task_id]
    
    if task["status"] != "completed" or task["file_path"] is None:
        raise HTTPException(status_code=400, detail="File is not ready yet")
        
    if not os.path.exists(task["file_path"]):
        raise HTTPException(status_code=404, detail="File not found on disk")
        
    # 回傳實體檔案
    return FileResponse(
        path=task["file_path"], 
        media_type="audio/mp4",
        filename=f"{task['source_id']}.m4a"
    )

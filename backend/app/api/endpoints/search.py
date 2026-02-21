from fastapi import APIRouter, Query
from typing import List
from pydantic import BaseModel
from app.services.youtube import search_youtube

router = APIRouter()

class SearchResultResponse(BaseModel):
    id: str
    title: str
    channel: str
    thumbnail_url: str
    duration_ms: int

@router.get("/search", response_model=List[SearchResultResponse])
def search_api(query: str = Query(..., description="The search keyword")):
    """
    接收前端查詢關鍵字，調用 yt_dlp 取得 YouTube 搜尋結果。
    """
    results = search_youtube(query)
    return results

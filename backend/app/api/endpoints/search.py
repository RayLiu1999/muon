from fastapi import APIRouter, Query, Request
from typing import List
from pydantic import BaseModel
from app.services.youtube import search_youtube
from app.core.security import limiter

router = APIRouter()


class SearchResultResponse(BaseModel):
    id: str
    title: str
    channel: str
    thumbnail_url: str
    duration_ms: int


@router.get("/search", response_model=List[SearchResultResponse])
@limiter.limit("30/minute")
def search_api(
    request: Request,
    query: str = Query(..., description="The search keyword"),
    page: int = Query(1, description="Page number for pagination"),
):
    """
    接收前端查詢關鍵字與頁數，調用 yt_dlp 取得 YouTube 搜尋結果。
    Rate Limit：每 IP 每分鐘 30 次。
    """
    results = search_youtube(query, page=page)
    return results

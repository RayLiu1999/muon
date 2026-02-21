import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_search_api_missing_query():
    """測試未提供 query 參數時應回傳 422 錯誤"""
    response = client.get("/api/search")
    assert response.status_code == 422

# 我們可以使用 unittest.mock 來 mock yt_dlp，避免測試時真的發送網路請求
from unittest.mock import patch

@patch('app.api.endpoints.search.search_youtube')
def test_search_api_success(mock_search):
    """測試搜尋 API 成功時的行為"""
    # 設定 mock 回傳值
    mock_search.return_value = [
        {
            "id": "test_id_1",
            "title": "Test Video 1",
            "channel": "Test Channel",
            "thumbnail_url": "https://example.com/thumb1.jpg",
            "duration_ms": 180000
        }
    ]

    response = client.get("/api/search?query=test")
    assert response.status_code == 200
    
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == 1
    assert data[0]["id"] == "test_id_1"
    assert data[0]["title"] == "Test Video 1"
    
    # 確認 mock 函式有被以正確的參數呼叫
    mock_search.assert_called_once_with("test")

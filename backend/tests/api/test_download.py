import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_download_api_missing_data():
    """測試發送下載請求但缺乏必要參數應回傳 422"""
    # 這裡的 endpoint 假設是 POST /api/download
    response = client.post("/api/download", json={"title": "Test Video"})
    # 缺少 source_id
    assert response.status_code == 422

from unittest.mock import patch, MagicMock

@patch('app.api.endpoints.download.start_background_download')
def test_download_api_success(mock_start_download):
    """測試成功發起下載請求"""
    payload = {
        "source_id": "test_id_123",
        "title": "Test Title",
        "thumbnail_url": ""
    }
    
    response = client.post("/api/download", json=payload)
    assert response.status_code == 200
    
    data = response.json()
    assert "task_id" in data
    assert data["status"] == "queued"
    
    # 確保有呼叫背景執行
    mock_start_download.assert_called_once()
    
def test_get_download_status_not_found():
    """測試查詢不存在的任務 ID"""
    response = client.get("/api/download/nonexistent_id/status")
    assert response.status_code == 404

from app.api.endpoints.download import download_tasks

def test_get_download_status_success():
    """測試查詢存在的任務進度"""
    download_tasks["valid_id"] = {
        "source_id": "test_id",
        "status": "downloading",
        "progress": 0.5,
        "file_path": None,
        "error": None
    }
    
    response = client.get("/api/download/valid_id/status")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "downloading"
    assert data["progress"] == 0.5
    
    # 清理假資料
    del download_tasks["valid_id"]

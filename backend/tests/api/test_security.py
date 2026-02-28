"""
API Key 驗證機制的測試

測試策略：
- 透過 monkeypatch 設定 API_KEY 環境變數來模擬生產環境
- 測試有效金鑰、無效金鑰、缺少 header 的各種情況
"""

import os
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch


@pytest.fixture
def client_with_key():
    """回傳一個已設定 API_KEY=test-secret-key 的 TestClient"""
    with patch.dict(os.environ, {"API_KEY": "test-secret-key"}):
        from app.main import app
        yield TestClient(app), "test-secret-key"


# ── 開發模式（API_KEY 未設定）────────────────────────────────────────────────

def test_no_api_key_env_allows_requests():
    """當 API_KEY 環境變數未設定時，所有請求應直接通過（開發模式）"""
    with patch.dict(os.environ, {}, clear=False):
        os.environ.pop("API_KEY", None)
        from app.main import app
        from unittest.mock import patch as mpatch
        with mpatch("app.api.endpoints.search.search_youtube", return_value=[]):
            client = TestClient(app)
            # 不帶任何 header 也能請求
            response = client.get("/api/search?query=test")
            assert response.status_code == 200


# ── 生產模式（API_KEY 已設定）────────────────────────────────────────────────

class TestApiKeyEnforcement:
    """當 API_KEY 環境變數設定後，各端點應強制驗證"""

    def test_valid_key_allows_search(self, client_with_key):
        """正確的 API Key 應允許存取 /api/search"""
        with patch("app.api.endpoints.search.search_youtube", return_value=[]):
            client, key = client_with_key
            response = client.get(
                "/api/search?query=test",
                headers={"X-API-Key": key},
            )
            assert response.status_code == 200

    def test_missing_key_returns_401(self, client_with_key):
        """缺少 X-API-Key header 應回傳 401"""
        client, _ = client_with_key
        response = client.get("/api/search?query=test")
        assert response.status_code == 401

    def test_wrong_key_returns_401(self, client_with_key):
        """帶入錯誤金鑰應回傳 401"""
        client, _ = client_with_key
        response = client.get(
            "/api/search?query=test",
            headers={"X-API-Key": "wrong-key"},
        )
        assert response.status_code == 401

    def test_valid_key_allows_download(self, client_with_key):
        """正確的 API Key 應允許發起下載請求"""
        with patch("app.api.endpoints.download.start_background_download"):
            client, key = client_with_key
            payload = {
                "source_id": "test_id",
                "title": "Test Title",
            }
            response = client.post(
                "/api/download",
                json=payload,
                headers={"X-API-Key": key},
            )
            assert response.status_code == 200

    def test_missing_key_blocks_download(self, client_with_key):
        """缺少金鑰時，下載請求應回傳 401"""
        client, _ = client_with_key
        payload = {
            "source_id": "test_id",
            "title": "Test Title",
        }
        response = client.post("/api/download", json=payload)
        assert response.status_code == 401

    def test_health_endpoint_no_key_needed(self, client_with_key):
        """健康檢查端點不需要 API Key"""
        client, _ = client_with_key
        response = client.get("/health")
        assert response.status_code == 200

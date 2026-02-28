"""
安全核心模組

提供：
- API Key 驗證 Dependency（verify_api_key）
- slowapi Rate Limiter 實例（limiter）
"""

import os
from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader
from slowapi import Limiter
from slowapi.util import get_remote_address

# ── Rate Limiter ────────────────────────────────────────────────────────────────
# 使用請求端 IP 作為識別 key
limiter = Limiter(key_func=get_remote_address)

# ── API Key 驗證 ────────────────────────────────────────────────────────────────
_API_KEY_HEADER = APIKeyHeader(name="X-API-Key", auto_error=False)


def verify_api_key(api_key: str | None = Security(_API_KEY_HEADER)) -> None:
    """
    FastAPI Dependency：驗證請求 Header 中的 X-API-Key。

    - 若 API_KEY 環境變數未設定，直接放行（方便本地開發與測試）
    - 若設定了 API_KEY，但 header 缺少或不符，回傳 401
    """
    expected = os.getenv("API_KEY", "")
    if not expected:
        # 開發模式：跳過驗證
        return

    if api_key != expected:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API Key",
            headers={"WWW-Authenticate": "ApiKey"},
        )

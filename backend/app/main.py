import asyncio
import os
from contextlib import asynccontextmanager
from fastapi import Depends, FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from app.api.endpoints import search, download
from app.core.security import limiter, verify_api_key
from app.services.downloader import periodic_cleanup


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    FastAPI lifespan：應用程式啟動時建立 TTL 清理排程（方案②），
    關閉時自動取消。
    """
    cleanup_task = asyncio.create_task(periodic_cleanup())
    yield
    cleanup_task.cancel()
    try:
        await cleanup_task
    except asyncio.CancelledError:
        pass


# ── FastAPI 初始化 ────────────────────────────────────────────────────────────
app = FastAPI(title="Muon Backend API", lifespan=lifespan)

# ── Rate Limiter ──────────────────────────────────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# ── CORS ──────────────────────────────────────────────────────────────────────
# ALLOWED_ORIGINS 以逗號分隔，例如 "https://example.com,https://api.example.com"
_raw_origins = os.getenv("ALLOWED_ORIGINS", "")
allowed_origins = [o.strip() for o in _raw_origins.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["X-API-Key", "Content-Type"],
)

# ── Routers（套用 API Key 驗證）──────────────────────────────────────────────
# API Key Dependency 僅套用在 /api/* 路由；健康檢查端點不受影響
_api_deps = [Depends(verify_api_key)]
app.include_router(search.router, prefix="/api", dependencies=_api_deps)
app.include_router(download.router, prefix="/api", dependencies=_api_deps)


# ── 公開端點（不需要 API Key）────────────────────────────────────────────────
@app.get("/", include_in_schema=False)
def read_root():
    return {"message": "Welcome to Muon Backend API"}


@app.get("/health", include_in_schema=False)
def health_check():
    return {"status": "ok"}

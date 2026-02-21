import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.api.endpoints import search, download
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


app = FastAPI(title="Muon Backend API", lifespan=lifespan)

app.include_router(search.router, prefix="/api")
app.include_router(download.router, prefix="/api")


@app.get("/")
def read_root():
    return {"message": "Welcome to Muon Backend API"}

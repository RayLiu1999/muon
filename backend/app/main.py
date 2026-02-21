from fastapi import FastAPI
from app.api.endpoints import search, download

app = FastAPI(title="Muon Backend API")

app.include_router(search.router, prefix="/api")
app.include_router(download.router, prefix="/api")

@app.get("/")
def read_root():
    return {"message": "Welcome to Muon Backend API"}

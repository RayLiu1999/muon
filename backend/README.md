# Muon Backend Service 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE)

_Read this in other languages: [English](README.md), [繁體中文](README_zh.md)_

This directory contains the backend service for the Muon music player application. Written in **Python + FastAPI**, it handles parsing YouTube search queries, fetching video information, and downloading audio/video in the background to the server for frontend access.

## 🎯 Core Features

- **Search API (`/api/search`)**: Integrates with [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) to query YouTube directly and parse the title, channel, thumbnail, and duration of search results.
- **Download API (`/api/download`)**: Provides background downloading. It not only supports audio-only tracks (defaulting to m4a) but can also forcefully extract universally iOS-compatible H.264 videos (packaged as mp4+aac).
- **Status API (`/api/status/{task_id}`)**: Provides asynchronous status responses for the frontend to regularly poll download progress.
- **Static File Serving (`/downloads`)**: Uses FastAPI's `StaticFiles` to serve physical files in streaming mode, allowing the frontend to play music directly.
- **Background Tasks & Cleanup**: Offers a time-based TTL (Time-To-Live) cache cleanup service to maintain system disk space.

## ⚙️ Environment Setup

We strongly recommend using **Docker Compose** for local development or deployment. A complete containerized workflow is already configured.

### Using Docker (📦 Recommended)

1. First, copy the environment variable template and modify it with your machine's IP:
   ```bash
   cp .env.example .env
   # Edit .env and change HOST_IP to your computer's local network IPv4 address (e.g., 192.168.50.35)
   ```
2. Start directly using Docker Compose (includes auto-building):
   ```bash
   docker compose up -d --build
   ```

The service will start at `http://${HOST_IP}:8000` (defaults to 127.0.0.1:8000 if not set).
You can view and directly test the API documentation (Swagger UI) at `http://${HOST_IP}:8000/docs`!

---

### Native Python (🐍 Development Mode)

If you need to debug the Python source code directly, you can run it using `uvicorn`:

1. **Create a virtual environment**:

   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: `venv\Scripts\activate`
   ```

2. **Install dependencies (Must ensure ffmpeg is installed)**:
   This system relies heavily on `ffmpeg` for audio conversion. Please ensure ffmpeg is installed on your host machine!

   ```bash
   pip install -r requirements.txt
   ```

3. **Start the FastAPI service**:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

## 📂 Folder Structure

- `/app`: Core application code.
  - `main.py`: FastAPI mount point, middleware, and route imports.
  - `api.py`: Core routing logic for search, download, and status.
  - `services/`: Encapsulates the `downloader.py` background download service and progress hooks.
  - `models/`: Pure data Pydantic definitions.
- `/downloads`: (Generated at runtime) Default physical path for storing parsed mp4/m4a playback files.
- `.env`: Basic configuration file for specifying the Host IP used by Docker Compose.

## 🔧 Maintenance Notes

- `yt-dlp` updates frequently. If YouTube changes its interface causing downloads to fail or searches to yield no results, please run `pip install -U yt-dlp` directly in the container or on the host to upgrade.
- If the iOS App switches to full-screen mode and displays a **black screen with only sound**, it means the ffmpeg conversion format deviated from the AVC(H.264) + AAC standard. Please modify the corresponding `postprocessor_args` parameters in `app/services/downloader.py` and rebuild the Docker image.
- **🤖 YouTube Bot Verification (`Sign in to confirm you’re not a bot`):** If your backend IP (e.g. deployed on a VPS) is blocked by YouTube, you can use a browser extension (like 'Get cookies.txt LOCALLY') to export your YouTube cookies as `cookies.txt` and place this file in the **root level of the `backend` directory**. The system will automatically detect it and use it to bypass the bot verification.

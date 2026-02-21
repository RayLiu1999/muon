import os
import yt_dlp
from typing import List, Dict, Any

def search_youtube(query: str, page: int = 1, limit: int = 20) -> List[Dict[str, Any]]:
    """
    使用 yt-dlp 搜尋 YouTube 影片，透過計算抓取數量模擬分頁。
    """
    ydl_opts = {
        'extract_flat': 'in_playlist', # 避免深度解析每一個影片的格式，加快搜尋速度
        'quiet': True,
        'no_warnings': True,
        'ignoreerrors': True,
        'default_search': 'ytsearch',  # 強制使用 youtube search
        'js_runtimes': 'node',  # 啟用 Node.js 解碼 YouTube JS challenge
    }

    # 使用 cookies.txt 繞過 YouTube bot 驗證 (VPS 必備)
    if os.path.isfile("cookies.txt"):
        ydl_opts['cookiefile'] = "cookies.txt"

    # 備用方案：Android player client (效果較不穩定)
    # ydl_opts['extractor_args'] = {'youtube': {'player_client': ['android', 'web']}}

    # 為了模擬分頁，我們需要讓 yt-dlp 抓到所需的總數量 (page * limit)
    total_needed = page * limit
    search_query = f"ytsearch{total_needed}:{query}"

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            info = ydl.extract_info(search_query, download=False)
            
            if not info or 'entries' not in info:
                return []
                
            results = []
            for entry in info['entries']:
                if entry:
                    # yt-dlp 抓到的 duration 會是秒，Flutter 需要毫秒
                    duration_sec = entry.get('duration') or 0
                    
                    # 篩選掉直播或找不到時長的內容
                    if duration_sec == 0:
                        continue
                        
                    results.append({
                        "id": entry.get('id'),
                        "title": entry.get('title'),
                        "channel": entry.get('uploader') or entry.get('channel') or "Unknown",
                        "thumbnail_url": entry.get('thumbnail') or f"https://i.ytimg.com/vi/{entry.get('id')}/hqdefault.jpg",
                        "duration_ms": int(duration_sec * 1000)
                    })
            
            # 進行分頁切片
            start_index = (page - 1) * limit
            return results[start_index:start_index + limit]
        except Exception as e:
            print(f"yt-dlp search error: {e}")
            return []

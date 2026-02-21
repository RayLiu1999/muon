import yt_dlp
from typing import List, Dict, Any

def search_youtube(query: str, max_results: int = 20) -> List[Dict[str, Any]]:
    """
    使用 yt-dlp 搜尋 YouTube 影片，回傳指定的數量。
    為了效能，我們只抽取資訊不下載。
    """
    ydl_opts = {
        'extract_flat': 'in_playlist', # 避免深度解析每一個影片的格式，加快搜尋速度
        'quiet': True,
        'no_warnings': True,
        'ignoreerrors': True,
        'default_search': 'ytsearch',  # 強制使用 youtube search
    }

    # "ytsearchN:query" 代表回傳 N 筆結果
    search_query = f"ytsearch{max_results}:{query}"

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
            return results
        except Exception as e:
            print(f"yt-dlp search error: {e}")
            return []

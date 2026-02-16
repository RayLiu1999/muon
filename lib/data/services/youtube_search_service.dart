import 'package:muon/data/models/search_result.dart';

/// YouTube 搜尋服務介面
///
/// 定義搜尋行為的抽象介面。
/// 真實實作會呼叫 YouTube Data API v3。
/// Mock 實作提供假資料供開發與測試使用。
abstract class YouTubeSearchService {
  /// 搜尋 YouTube 影片
  ///
  /// [query] 搜尋關鍵字
  /// [maxResults] 最大結果數（預設 20）
  Future<List<SearchResult>> search(String query, {int maxResults = 20});
}

/// Mock YouTube 搜尋服務
///
/// 使用假資料，不需 YouTube API Key。
class MockYouTubeSearchService implements YouTubeSearchService {
  @override
  Future<List<SearchResult>> search(String query, {int maxResults = 20}) async {
    // 模擬網路延遲
    await Future.delayed(const Duration(milliseconds: 800));

    // 回傳假資料
    return List.generate(
      maxResults > 10 ? 10 : maxResults,
      (i) => SearchResult(
        videoId: 'mock-video-${query.hashCode.abs()}-$i',
        title: '$query 相關影片 ${i + 1}',
        channel: '測試頻道 ${i % 3 + 1}',
        thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        duration: '${(i % 5) + 2}:${(i * 13 % 60).toString().padLeft(2, '0')}',
      ),
    );
  }
}

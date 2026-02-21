import 'package:dio/dio.dart';
import 'package:muon/core/utils/duration_formatter.dart';
import 'package:muon/data/models/search_result.dart';
import 'package:muon/data/services/youtube_search_service.dart';

/// 真實 YouTube 搜尋服務
///
/// 呼叫後端 FastAPI 的 /api/search 端點
class RealYouTubeSearchService implements YouTubeSearchService {
  final Dio _dio;
  final String baseUrl;

  RealYouTubeSearchService(this._dio, {required this.baseUrl});

  @override
  Future<List<SearchResult>> search(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/search',
        queryParameters: {'query': query, 'page': page, 'limit': limit},
      );

      final data = response.data as List<dynamic>;

      return data.map((item) {
        final durationMs = item['duration_ms'] as int;
        return SearchResult(
          videoId: item['id'] as String,
          title: item['title'] as String,
          channel: item['channel'] as String,
          thumbnailUrl: item['thumbnail_url'] as String,
          duration: DurationFormatter.format(
            Duration(milliseconds: durationMs),
          ),
        );
      }).toList();
    } catch (e) {
      throw Exception('搜尋失敗: $e');
    }
  }
}

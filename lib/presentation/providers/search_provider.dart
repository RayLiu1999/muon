import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muon/data/models/search_result.dart';
import 'package:muon/data/services/youtube_search_service.dart';

part 'search_provider.g.dart';

/// YouTube 搜尋服務 Provider
@Riverpod(keepAlive: true)
YouTubeSearchService youtubeSearchService(YoutubeSearchServiceRef ref) {
  // 暫時使用 Mock，未來替換為真實 API
  return MockYouTubeSearchService();
}

/// 搜尋結果 Provider
@riverpod
class SearchNotifier extends _$SearchNotifier {
  @override
  AsyncValue<List<SearchResult>> build() {
    return const AsyncValue.data([]);
  }

  /// 執行搜尋
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final service = ref.read(youtubeSearchServiceProvider);
      final results = await service.search(query);
      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 清空搜尋結果
  void clear() {
    state = const AsyncValue.data([]);
  }
}

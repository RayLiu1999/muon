import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muon/data/models/search_result.dart';
import 'package:muon/data/services/youtube_search_service.dart';

import 'package:muon/presentation/providers/dio_provider.dart';
import 'package:muon/presentation/providers/database_provider.dart';
import 'package:muon/data/services/real_youtube_search_service.dart';

part 'search_provider.g.dart';

/// YouTube 搜尋服務 Provider
@Riverpod(keepAlive: true)
YouTubeSearchService youtubeSearchService(YoutubeSearchServiceRef ref) {
  final dio = ref.watch(dioProvider);
  final baseUrl = ref.watch(backendBaseUrlProvider);
  return RealYouTubeSearchService(dio, baseUrl: baseUrl);
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

      // 與本地 DB 比對是否已下載
      final db = ref.read(databaseProvider);
      final updatedResults = <SearchResult>[];
      for (final result in results) {
        final existingItem = await db.mediaDao.findBySourceId(result.videoId);
        updatedResults.add(result.copyWith(isDownloaded: existingItem != null));
      }

      state = AsyncValue.data(updatedResults);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 清空搜尋結果
  void clear() {
    state = const AsyncValue.data([]);
  }
}

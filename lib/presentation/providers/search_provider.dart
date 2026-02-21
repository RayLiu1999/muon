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
  String _lastQuery = '';
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

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
    _lastQuery = query.trim();
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;

    try {
      final service = ref.read(youtubeSearchServiceProvider);
      final results = await service.search(_lastQuery, page: _currentPage);

      // 與本地 DB 比對是否已下載
      final db = ref.read(databaseProvider);
      final updatedResults = <SearchResult>[];
      for (final result in results) {
        final existingItem = await db.mediaDao.findBySourceId(result.videoId);
        updatedResults.add(result.copyWith(isDownloaded: existingItem != null));
      }

      _hasMore = results.length >= 20;
      state = AsyncValue.data(updatedResults);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 載入更多
  Future<void> loadMore() async {
    if (_isLoadingMore ||
        !_hasMore ||
        _lastQuery.isEmpty ||
        state.valueOrNull == null)
      return;

    _isLoadingMore = true;
    state = AsyncValue.data(List.of(state.valueOrNull!)); // 觸發 UI 更新以顯示 spinner
    _currentPage++;

    try {
      final service = ref.read(youtubeSearchServiceProvider);
      final results = await service.search(_lastQuery, page: _currentPage);

      if (results.isEmpty) {
        _hasMore = false;
      } else {
        final db = ref.read(databaseProvider);
        final updatedResults = <SearchResult>[];
        for (final result in results) {
          final existingItem = await db.mediaDao.findBySourceId(result.videoId);
          updatedResults.add(
            result.copyWith(isDownloaded: existingItem != null),
          );
        }

        _hasMore = results.length >= 20;
        final currentResults = state.valueOrNull!;
        state = AsyncValue.data([...currentResults, ...updatedResults]);
      }
    } catch (e) {
      _currentPage--;
    } finally {
      if (_isLoadingMore) {
        _isLoadingMore = false;
        state = AsyncValue.data(List.of(state.valueOrNull!)); // 更新移除 spinner
      }
    }
  }

  /// 清空搜尋結果
  void clear() {
    _lastQuery = '';
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    state = const AsyncValue.data([]);
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/data/models/search_result.dart';
import 'package:muon/presentation/providers/download_provider.dart';
import 'package:muon/presentation/providers/media_provider.dart';
import 'package:muon/presentation/providers/search_provider.dart';

import 'package:muon/presentation/providers/search_history_provider.dart';

/// 搜尋頁 — YouTube 搜尋 + 下載
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    _searchController.text = query;
    _focusNode.unfocus();
    ref.read(searchNotifierProvider.notifier).search(query);
    ref.read(searchHistoryNotifierProvider.notifier).addRecord(query);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final searchNotifier = ref.read(searchNotifierProvider.notifier);
    final isSearching =
        searchState.isLoading && searchState.valueOrNull == null;
    final hasResults = searchState.valueOrNull?.isNotEmpty ?? false;
    final isSearchFocused = _focusNode.hasFocus;
    final theme = Theme.of(context);

    // 當有搜尋結果但不聚焦輸入框時，隱藏歷史紀錄
    final showHistory = isSearchFocused || (!hasResults && !isSearching);

    return Scaffold(
      appBar: AppBar(title: const Text('搜尋')),
      body: Column(
        children: [
          // 搜尋輸入框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: '搜尋音樂...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchNotifierProvider.notifier).clear();
                          _focusNode.requestFocus();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: _submitSearch,
            ),
          ),

          // 歷史紀錄或搜尋結果
          Expanded(
            child: showHistory
                ? _buildSearchHistory(theme)
                : searchState.when(
                    data: (results) {
                      if (results.isEmpty) {
                        return _buildEmptyState(theme, text: '無符合結果');
                      }
                      return _buildResultList(results, searchNotifier);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text(
                        '搜尋失敗：$error',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 搜尋歷史
  Widget _buildSearchHistory(ThemeData theme) {
    final history = ref.watch(searchHistoryNotifierProvider);

    if (history.isEmpty) {
      return _buildEmptyState(theme, text: '搜尋 YouTube 音樂');
    }

    return ListView.builder(
      itemCount: history.length + 1, // +1 給標頭
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('最近搜尋', style: theme.textTheme.titleSmall),
                TextButton(
                  onPressed: () {
                    ref.read(searchHistoryNotifierProvider.notifier).clearAll();
                  },
                  child: const Text('清除全部'),
                ),
              ],
            ),
          );
        }

        final query = history[index - 1];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(query),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              ref
                  .read(searchHistoryNotifierProvider.notifier)
                  .removeRecord(query);
            },
          ),
          onTap: () => _submitSearch(query),
        );
      },
    );
  }

  /// 空狀態
  Widget _buildEmptyState(ThemeData theme, {required String text}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('搜尋 YouTube 音樂', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  /// 搜尋結果列表
  Widget _buildResultList(List<SearchResult> results, SearchNotifier notifier) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: results.length + (notifier.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final result = results[index];
        return _SearchResultTile(result: result);
      },
    );
  }
}

/// 搜尋結果列表項目
class _SearchResultTile extends ConsumerWidget {
  final SearchResult result;

  const _SearchResultTile({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadNotifierProvider);
    final progress = downloadState[result.videoId];
    final isDownloading = progress != null && progress >= 0;

    final mediaListAsync = ref.watch(allMediaItemsProvider);
    final isAlreadyDownloaded =
        mediaListAsync.valueOrNull?.any((m) => m.sourceId == result.videoId) ??
        false;

    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 85, // 16:9 比例 (48 * 16 / 9 ≈ 85)
          height: 48,
          color: theme.cardTheme.color,
          child: result.thumbnailUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: result.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.play_circle_outline, size: 24),
                )
              : const Icon(Icons.play_circle_outline, size: 24),
        ),
      ),
      title: Text(
        result.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              result.channel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(' · ${result.duration}', style: theme.textTheme.bodySmall),
        ],
      ),
      trailing: _buildTrailingAction(
        ref,
        theme,
        isDownloading,
        progress,
        isAlreadyDownloaded,
      ),
    );
  }

  /// 建立右側按鈕（下載/下載中/已下載）
  Widget _buildTrailingAction(
    WidgetRef ref,
    ThemeData theme,
    bool isDownloading,
    double? progress,
    bool isAlreadyDownloaded,
  ) {
    // 統一按鈕的寬高為 48，確保視覺上對齊（IconButton 的預設範圍）
    if (isAlreadyDownloaded) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(Icons.check, color: theme.colorScheme.primary, size: 24),
        ),
      );
    }

    if (isDownloading) {
      // 剛建立任務時 progress 會是 0.0，轉為 null 可以讓進度條變成「讀取中」的無限旋轉狀態
      final displayProgress = progress == 0.0 ? null : progress;
      return SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: displayProgress,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: () {
        ref
            .read(downloadNotifierProvider.notifier)
            .startDownload(
              sourceId: result.videoId,
              title: result.title,
              channel: result.channel,
              duration: result.duration,
              thumbnailUrl: result.thumbnailUrl,
            );
      },
    );
  }
}

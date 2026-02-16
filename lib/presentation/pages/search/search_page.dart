import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/data/models/search_result.dart';
import 'package:muon/presentation/providers/download_provider.dart';
import 'package:muon/presentation/providers/search_provider.dart';

/// 搜尋頁 — YouTube 搜尋 + 下載
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('搜尋'),
      ),
      body: Column(
        children: [
          // 搜尋輸入框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋音樂...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchNotifierProvider.notifier).clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (query) {
                ref.read(searchNotifierProvider.notifier).search(query);
              },
            ),
          ),

          // 搜尋結果
          Expanded(
            child: searchState.when(
              data: (results) {
                if (results.isEmpty) {
                  return _buildEmptyState(theme);
                }
                return _buildResultList(results);
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

  /// 空狀態
  Widget _buildEmptyState(ThemeData theme) {
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
          Text(
            '搜尋 YouTube 音樂',
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  /// 搜尋結果列表
  Widget _buildResultList(List<SearchResult> results) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: results.length,
      itemBuilder: (context, index) {
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
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Container(
            color: theme.cardTheme.color,
            child: const Icon(Icons.play_circle_outline, size: 24),
          ),
        ),
      ),
      title: Text(
        result.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
      ),
      subtitle: Text(
        '${result.channel} · ${result.duration}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: _buildTrailingAction(ref, isDownloading, progress),
    );
  }

  /// 建立右側按鈕（下載/下載中/已下載）
  Widget _buildTrailingAction(
    WidgetRef ref,
    bool isDownloading,
    double? progress,
  ) {
    if (result.isDownloaded) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 24);
    }

    if (isDownloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2,
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: () {
        ref.read(downloadNotifierProvider.notifier).startDownload(
              sourceId: result.videoId,
              title: result.title,
              thumbnailUrl: result.thumbnailUrl,
            );
      },
    );
  }
}

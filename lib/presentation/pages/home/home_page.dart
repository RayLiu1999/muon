import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/presentation/providers/audio_provider.dart';
import 'package:muon/presentation/providers/media_provider.dart';
import 'package:audio_service/audio_service.dart' as audio;
import 'package:muon/presentation/widgets/media_list_tile.dart';

/// 首頁 — 媒體庫
///
/// 分三個 section：最近下載、最近播放、我的最愛。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allItems = ref.watch(allMediaItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('媒體庫')),
      body: allItems.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildMediaList(context, ref, items);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            '載入失敗：$error',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  /// 空狀態提示
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('媒體庫是空的', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('搜尋並下載音樂開始使用', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  /// 媒體列表
  Widget _buildMediaList(
    BuildContext context,
    WidgetRef ref,
    List<MediaItem> items,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // 為 MiniPlayer 留空間
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MediaListTile(
          title: item.title,
          channel: item.channel,
          durationMs: item.durationMs,
          thumbnailPath: item.thumbnailPath,
          isFavorite: item.favorite,
          onTap: () {
            final handler = ref.read(audioHandlerProvider);
            final queue = items.map((e) {
              Uri? artUri;
              if (e.thumbnailPath.isNotEmpty) {
                artUri = e.thumbnailPath.startsWith('http')
                    ? Uri.tryParse(e.thumbnailPath)
                    : Uri.file(e.thumbnailPath);
              }
              return audio.MediaItem(
                id: e.id,
                title: e.title,
                artist: e.channel,
                duration: Duration(milliseconds: e.durationMs),
                artUri: artUri,
                extras: {'filePath': e.filePath},
              );
            }).toList();
            handler.loadPlaylist(queue, startIndex: index);
          },
          onFavoriteToggle: () {
            ref
                .read(mediaRepositoryProvider)
                .toggleFavorite(item.id, !item.favorite);
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('刪除歌曲'),
                content: Text('確定要從裝置中刪除「${item.title}」嗎？此動作將會刪除實體檔案。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(mediaRepositoryProvider)
                          .deleteMediaItem(item.id);
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '刪除',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/presentation/providers/audio_provider.dart';
import 'package:muon/presentation/providers/playlist_provider.dart';
import 'package:muon/presentation/providers/media_provider.dart';
import 'package:audio_service/audio_service.dart' as audio;
import 'package:muon/presentation/widgets/media_list_tile.dart';
import 'package:muon/presentation/widgets/media_action_sheet.dart';

/// 播放清單內容頁面
class PlaylistDetailPage extends ConsumerWidget {
  final String playlistId;
  final String title;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(playlistMediaItemsProvider(playlistId));
    // 判斷是否為系統清單，系統清單的話不能「移除歌曲」（例如：我的最愛、全部歌曲）
    // 但為求簡化，我們可以就顯示 items 即可

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !Platform.isMacOS,
        title: Text(title),
        actions: [
          itemsAsync.whenData((items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    final handler = ref.read(audioHandlerProvider);
                    final queue = items
                        .map((e) => _toAudioMediaItem(e))
                        .toList();
                    handler.loadPlaylist(
                      queue,
                      startIndex: 0,
                      collectionId: playlistId,
                    );
                  },
                );
              }).valueOrNull ??
              const SizedBox.shrink(),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text('此播放清單是空的', style: theme.textTheme.titleMedium),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(playlistMediaItemsProvider(playlistId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return MediaListTile(
                  title: item.title,
                  channel: item.channel,
                  durationMs: item.durationMs,
                  thumbnailPath: item.thumbnailPath,
                  isFavorite: item.favorite,
                  onFavoriteToggle: () {
                    ref
                        .read(mediaRepositoryProvider)
                        .toggleFavorite(item.id, !item.favorite);
                  },
                  onTap: () {
                    final handler = ref.read(audioHandlerProvider);
                    final queue = items
                        .map((e) => _toAudioMediaItem(e))
                        .toList();
                    handler.loadPlaylist(
                      queue,
                      startIndex: index,
                      collectionId: playlistId,
                    );
                  },
                  onMoreTap: () {
                    // 提供移除功能以及通用操作
                    showMediaActionSheet(
                      context,
                      ref,
                      item,
                      extraActions: [
                        ListTile(
                          leading: const Icon(Icons.playlist_remove),
                          title: const Text('從此播放清單移除'),
                          onTap: () {
                            ref
                                .read(playlistNotifierProvider.notifier)
                                .removeMediaFromPlaylist(playlistId, item.id);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('載入失敗：$err')),
      ),
    );
  }

  audio.MediaItem _toAudioMediaItem(MediaItem e) {
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
  }
}

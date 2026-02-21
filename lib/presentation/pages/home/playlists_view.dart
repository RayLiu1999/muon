import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muon/presentation/providers/playlist_provider.dart';

/// 顯示播放清單列表的 View (用於 HomePage 的 Tab)
class PlaylistsView extends ConsumerWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(allPlaylistsProvider);
    final theme = Theme.of(context);

    return playlistsAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.queue_music,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text('目前沒有播放清單', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('點擊歌曲旁邊的選單來建立', style: theme.textTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            final isSystem = playlist.type == 'system';
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSystem ? Icons.favorite : Icons.playlist_play,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(playlist.name),
              subtitle: Text(isSystem ? '系統清單' : '自訂清單'),
              trailing: isSystem
                  ? null
                  : PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('刪除清單'),
                              content: Text('確定要刪除「${playlist.name}」嗎？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(
                                    '刪除',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref
                                .read(playlistNotifierProvider.notifier)
                                .deletePlaylist(playlist.id);
                          }
                        } else if (value == 'rename') {
                          final controller = TextEditingController(
                            text: playlist.name,
                          );
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('重新命名'),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: '輸入新名稱',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, null),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, controller.text),
                                  child: const Text('儲存'),
                                ),
                              ],
                            ),
                          );
                          if (newName != null && newName.trim().isNotEmpty) {
                            ref
                                .read(playlistNotifierProvider.notifier)
                                .updatePlaylistName(
                                  playlist.id,
                                  newName.trim(),
                                );
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('重新命名'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('刪除清單'),
                        ),
                      ],
                    ),
              onTap: () {
                context.push('/playlist/${playlist.id}', extra: playlist.name);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('載入失敗：$err')),
    );
  }
}

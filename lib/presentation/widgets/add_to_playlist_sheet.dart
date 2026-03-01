import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/core/utils/app_toast.dart';
import 'package:muon/presentation/providers/playlist_provider.dart';

/// 顯示「加入播放清單」底部對話框（支援單項或批次）
Future<void> showAddToPlaylistSheet(
  BuildContext context,
  List<String> mediaItemIds,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true, // 允許配合鍵盤彈出調整高度
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _AddToPlaylistSheet(mediaItemIds: mediaItemIds),
  );
}

class _AddToPlaylistSheet extends ConsumerStatefulWidget {
  final List<String> mediaItemIds;

  const _AddToPlaylistSheet({required this.mediaItemIds});

  @override
  ConsumerState<_AddToPlaylistSheet> createState() =>
      _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<_AddToPlaylistSheet> {
  final _newPlaylistController = TextEditingController();

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  void _createAndAdd() async {
    final name = _newPlaylistController.text.trim();
    if (name.isEmpty) return;

    final notifier = ref.read(playlistNotifierProvider.notifier);
    // 先建立清單
    await notifier.createPlaylist(name);
    _newPlaylistController.clear();
    // 雖然無法馬上拿到新建的 id 放進迴圈中，但此處可先不處理自動加入，讓使用者自己點擊新建出來的項目。
    // 如果要直接加入，需要更複雜的回傳 id 機制，為了穩定我們讓它產生清單即可。
  }

  @override
  Widget build(BuildContext context) {
    // 這裡我們篩選出使用者自訂的清單 (type == 'user')
    // 如果想讓他們也能加入系統清單，可以直接全列，但通常「我的最愛」有獨立按鈕了
    final playlistsAsync = ref.watch(allPlaylistsProvider);
    final theme = Theme.of(context);

    return Padding(
      // 確保在有鍵盤時不會被遮擋
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '加入播放清單',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // 建立新清單區塊
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newPlaylistController,
                  decoration: const InputDecoration(
                    hintText: '輸入新清單名稱...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onSubmitted: (_) => _createAndAdd(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _createAndAdd, child: const Text('建立')),
            ],
          ),
          const Divider(height: 32),
          // 現有清單列表
          Flexible(
            child: playlistsAsync.when(
              data: (playlists) {
                final userPlaylists = playlists
                    .where((p) => p.type == 'user')
                    .toList();
                if (userPlaylists.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('目前沒有自訂清單')),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: userPlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = userPlaylists[index];
                    return ListTile(
                      leading: const Icon(Icons.playlist_play),
                      title: Text(playlist.name),
                      onTap: () async {
                        final actions = widget.mediaItemIds.map((id) {
                          return ref
                              .read(playlistNotifierProvider.notifier)
                              .addMediaToPlaylist(playlist.id, id);
                        });
                        await Future.wait(actions);

                        if (context.mounted) {
                          Navigator.pop(context);
                          showAppToast(
                            context,
                            widget.mediaItemIds.length > 1
                                ? '已將 ${widget.mediaItemIds.length} 項目加入 ${playlist.name}'
                                : '已加入 ${playlist.name}',
                          );
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(child: Text('載入失敗：$err')),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

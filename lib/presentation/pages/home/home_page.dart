import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/data/database/daos/media_dao.dart';
import 'package:muon/presentation/providers/audio_provider.dart';
import 'package:muon/presentation/providers/media_provider.dart';
import 'package:audio_service/audio_service.dart' as audio;
import 'package:muon/presentation/widgets/media_list_tile.dart';
import 'package:muon/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:muon/presentation/widgets/media_action_sheet.dart';
import 'package:muon/presentation/pages/home/playlists_view.dart';

/// 首頁 — 媒體庫
///
/// 分三個 section：最近下載、最近播放、我的最愛。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final Set<String> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _showBatchDeleteDialog(BuildContext context) {
    if (_selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批次刪除'),
        content: Text('確定要從裝置中刪除這 ${_selectedIds.length} 首歌曲嗎？此動作將會刪除實體檔案。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final repo = ref.read(mediaRepositoryProvider);
              for (final id in _selectedIds.toList()) {
                await repo.deleteMediaItem(id);
              }
              if (mounted) {
                _clearSelection();
              }
            },
            child: Text(
              '刪除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<MediaSortOption> _buildSortItem(
    MediaSortOption value,
    String text,
    MediaSortOption current,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            current == value
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            size: 20,
            color: current == value
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(allMediaItemsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _isSelectionMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                ),
                title: Text('已選擇 ${_selectedIds.length} 項'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.playlist_add),
                    onPressed: () {
                      if (_selectedIds.isEmpty) return;
                      // 批次加入播放清單
                      showAddToPlaylistSheet(context, _selectedIds.toList());
                      _clearSelection();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showBatchDeleteDialog(context),
                  ),
                ],
              )
            : AppBar(
                title: const Text('媒體庫'),
                actions: [
                  PopupMenuButton<MediaSortOption>(
                    icon: const Icon(Icons.sort),
                    tooltip: '排序方式',
                    onSelected: (option) {
                      ref
                          .read(mediaSortOptionNotifierProvider.notifier)
                          .updateSort(option);
                    },
                    itemBuilder: (context) {
                      final currentSort = ref.watch(
                        mediaSortOptionNotifierProvider,
                      );
                      return [
                        _buildSortItem(
                          MediaSortOption.dateDesc,
                          '下載時間 (新到舊)',
                          currentSort,
                        ),
                        _buildSortItem(
                          MediaSortOption.dateAsc,
                          '下載時間 (舊到新)',
                          currentSort,
                        ),
                        _buildSortItem(
                          MediaSortOption.sizeDesc,
                          '檔案大小 (大到小)',
                          currentSort,
                        ),
                        _buildSortItem(
                          MediaSortOption.sizeAsc,
                          '檔案大小 (小到大)',
                          currentSort,
                        ),
                        _buildSortItem(
                          MediaSortOption.playCountDesc,
                          '播放頻率 (多到少)',
                          currentSort,
                        ),
                      ];
                    },
                  ),
                ],
                bottom: const TabBar(
                  tabs: [
                    Tab(text: '所有歌曲'),
                    Tab(text: '播放清單'),
                  ],
                ),
              ),
        body: TabBarView(
          children: [
            // 第一頁：所有歌曲
            allItems.when(
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
            // 第二頁：播放清單
            const PlaylistsView(),
          ],
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
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allMediaItemsProvider);
      },
      child: ListView.builder(
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
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedIds.contains(item.id),
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(item.id);
                return;
              }

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
              if (!_isSelectionMode) {
                _toggleSelection(item.id);
              }
            },
            onMoreTap: () {
              if (!_isSelectionMode) {
                showMediaActionSheet(
                  context,
                  ref,
                  item,
                  onDeleted: () {
                    // 如果需要刷新可在此處理
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}

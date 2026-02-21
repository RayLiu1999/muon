import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/presentation/providers/media_provider.dart';
import 'package:muon/presentation/widgets/add_to_playlist_sheet.dart';

/// 顯示媒體項目的操作選單（加入清單、詳細資訊、刪除）
Future<void> showMediaActionSheet(
  BuildContext context,
  WidgetRef ref,
  MediaItem item, {
  bool showDelete = true,
  VoidCallback? onDeleted,
  List<Widget>? extraActions,
}) async {
  final theme = Theme.of(context);

  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (extraActions != null) ...[...extraActions, const Divider()],
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('加入播放清單'),
              onTap: () {
                Navigator.of(context).pop();
                showAddToPlaylistSheet(context, [item.id]);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('詳細資訊'),
              onTap: () {
                Navigator.of(context).pop();
                _showMediaInfoDialog(context, item);
              },
            ),
            if (showDelete)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  '從裝置中刪除',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('刪除歌曲'),
                      content: const Text('確定要從裝置中刪除這首歌曲嗎？此動作將會刪除實體檔案。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            '刪除',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref
                        .read(mediaRepositoryProvider)
                        .deleteMediaItem(item.id);
                    onDeleted?.call();
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

void _showMediaInfoDialog(BuildContext context, MediaItem item) {
  final formatSize = (int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  };

  final formatter = DateFormat('yyyy-MM-dd HH:mm');
  final fileSizeStr = formatSize(item.fileSize);
  final createdAtStr = formatter.format(item.createdAt);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('詳細資訊'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('標題', item.title),
            _buildInfoRow(
              '頻道 / 歌手',
              item.channel.isNotEmpty ? item.channel : '未知',
            ),
            const SizedBox(height: 12),
            _buildInfoRow('檔案大小', fileSizeStr),
            const SizedBox(height: 12),
            _buildInfoRow('下載時間', createdAtStr),
            const SizedBox(height: 12),
            const Text(
              '檔案路徑',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(item.filePath, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('關閉'),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(value, style: const TextStyle(fontSize: 14)),
    ],
  );
}

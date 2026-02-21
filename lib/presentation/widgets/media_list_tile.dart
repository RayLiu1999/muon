import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:muon/core/utils/duration_formatter.dart';

/// 媒體項目列表元件
///
/// 顯示縮圖、標題、頻道、時長、我的最愛按鈕。
class MediaListTile extends StatelessWidget {
  /// 標題
  final String title;

  /// 頻道名稱
  final String channel;

  /// 時長（毫秒）
  final int durationMs;

  /// 縮圖路徑（本機路徑）
  final String? thumbnailPath;

  /// 是否為我的最愛
  final bool isFavorite;

  /// 點擊回呼
  final VoidCallback? onTap;

  /// 最愛按鈕回呼
  final VoidCallback? onFavoriteToggle;

  /// 長按回呼
  final VoidCallback? onLongPress;

  const MediaListTile({
    super.key,
    required this.title,
    required this.channel,
    required this.durationMs,
    this.thumbnailPath,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildThumbnail(theme),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
      ),
      subtitle: Text(
        '$channel · ${DurationFormatter.formatMs(durationMs)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? theme.colorScheme.primary : theme.iconTheme.color,
          size: 20,
        ),
        onPressed: onFavoriteToggle,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  /// 建立縮圖
  Widget _buildThumbnail(ThemeData theme) {
    Widget imageContent;
    if (thumbnailPath != null && thumbnailPath!.isNotEmpty) {
      if (thumbnailPath!.startsWith('http')) {
        imageContent = CachedNetworkImage(
          imageUrl: thumbnailPath!,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) =>
              const Icon(Icons.music_note, size: 24),
        );
      } else {
        imageContent = Image.file(
          File(thumbnailPath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.music_note, size: 24),
        );
      }
    } else {
      imageContent = const Icon(Icons.music_note, size: 24);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 48,
        height: 48,
        color: theme.cardTheme.color,
        child: imageContent,
      ),
    );
  }
}

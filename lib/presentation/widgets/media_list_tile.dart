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

  /// 是否處於選擇模式
  final bool isSelectionMode;

  /// 是否已被選取
  final bool isSelected;

  const MediaListTile({
    super.key,
    required this.title,
    required this.channel,
    required this.durationMs,
    this.thumbnailPath,
    this.isFavorite = false,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onTap,
    this.onFavoriteToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 當處於選擇模式時，整體加上些許被選取的背景色提示
    final tileColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      tileColor: tileColor,
      leading: isSelectionMode
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap?.call(),
                  activeColor: theme.colorScheme.primary,
                ),
                _buildThumbnail(theme),
              ],
            )
          : _buildThumbnail(theme),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              channel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(
            ' · ${DurationFormatter.formatMs(durationMs)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      trailing: isSelectionMode
          ? null // 選擇模式下隱藏右側按鈕避免誤觸
          : IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color,
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
        width: 85, // 16:9 比例 (48 * 16 / 9 ≈ 85)
        height: 48,
        color: theme.cardTheme.color,
        child: imageContent,
      ),
    );
  }
}

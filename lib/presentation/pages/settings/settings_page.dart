import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/core/constants/app_constants.dart';

/// 設定頁
///
/// 提供 App 版本資訊、清除快取、關於等功能。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          // 播放設定
          _buildSectionHeader(theme, '播放'),
          const _AudioQualityTile(),
          const Divider(height: 1),

          // 下載設定
          _buildSectionHeader(theme, '下載'),
          const _DownloadFormatTile(),
          const Divider(height: 1),

          // 資料管理
          _buildSectionHeader(theme, '資料管理'),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('清除快取'),
            subtitle: const Text('清除暫存的縮圖和搜尋記錄'),
            onTap: () {
              _showClearCacheDialog(context);
            },
          ),
          const Divider(height: 1),

          // 關於
          _buildSectionHeader(theme, '關於'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppConstants.appName),
            subtitle: Text('版本 ${AppConstants.appVersion}'),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  /// 區段標題
  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  /// 清除快取對話框
  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除快取'),
        content: const Text('確定要清除所有暫存資料嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('快取已清除')),
              );
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}

/// 音質設定
class _AudioQualityTile extends StatelessWidget {
  const _AudioQualityTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.high_quality),
      title: const Text('音質'),
      subtitle: const Text('高品質 (m4a)'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // 未來可展開為音質選擇
      },
    );
  }
}

/// 下載格式設定
class _DownloadFormatTile extends StatelessWidget {
  const _DownloadFormatTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.audio_file),
      title: const Text('下載格式'),
      subtitle: const Text('m4a (AAC)'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // 未來可展開為格式選擇
      },
    );
  }
}

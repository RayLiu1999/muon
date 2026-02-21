import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/core/constants/app_constants.dart';
import 'package:muon/presentation/providers/settings_provider.dart';

/// 設定頁
///
/// 提供 App 版本資訊、清除快取、關於等功能。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // 外觀設定
          _buildSectionHeader(theme, '外觀'),
          const _ThemeModeTile(),
          const Divider(height: 1),

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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('快取已清除')));
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}

/// 音質設定
class _AudioQualityTile extends ConsumerWidget {
  const _AudioQualityTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quality = ref.watch(audioQualityProvider);

    return ListTile(
      leading: const Icon(Icons.high_quality),
      title: const Text('音質'),
      subtitle: Text(quality == 'best' ? '最高品質 (best)' : '基本品質 (worstaudio)'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('選擇音質'),
            children: [
              RadioListTile<String>(
                title: const Text('最高品質 (best)'),
                value: 'best',
                groupValue: quality,
                onChanged: (val) {
                  ref.read(audioQualityProvider.notifier).updateQuality(val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: const Text('基本品質 (worstaudio)'),
                value: 'worstaudio',
                groupValue: quality,
                onChanged: (val) {
                  ref.read(audioQualityProvider.notifier).updateQuality(val!);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 下載格式設定
class _DownloadFormatTile extends ConsumerWidget {
  const _DownloadFormatTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(downloadFormatProvider);

    String formatText;
    switch (format) {
      case 'mp4':
        formatText = 'mp4 (影片+音訊)';
        break;
      case 'mp3':
        formatText = 'mp3 (僅音訊)';
        break;
      default:
        formatText = 'm4a (預設/僅音訊)';
    }

    return ListTile(
      leading: const Icon(Icons.download),
      title: const Text('下載格式'),
      subtitle: Text(formatText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('選擇格式'),
            children: [
              RadioListTile<String>(
                title: const Text('m4a (預設/僅音訊)'),
                value: 'm4a',
                groupValue: format,
                onChanged: (val) {
                  ref.read(downloadFormatProvider.notifier).updateFormat(val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: const Text('mp4 (影片+音訊)'),
                value: 'mp4',
                groupValue: format,
                onChanged: (val) {
                  ref.read(downloadFormatProvider.notifier).updateFormat(val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: const Text('mp3 (僅音訊)'),
                value: 'mp3',
                groupValue: format,
                onChanged: (val) {
                  ref.read(downloadFormatProvider.notifier).updateFormat(val!);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 外觀主題設定
class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeNotifierProvider);

    String modeText;
    switch (mode) {
      case 'light':
        modeText = '淺色模式';
        break;
      case 'dark':
        modeText = '深色模式';
        break;
      default:
        modeText = '跟隨系統';
    }

    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('主題外觀'),
      subtitle: Text(modeText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('選擇外觀主題'),
            children: [
              RadioListTile<String>(
                title: const Text('跟隨系統'),
                value: 'system',
                groupValue: mode,
                onChanged: (val) {
                  ref
                      .read(themeModeNotifierProvider.notifier)
                      .updateThemeMode(val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: const Text('淺色模式'),
                value: 'light',
                groupValue: mode,
                onChanged: (val) {
                  ref
                      .read(themeModeNotifierProvider.notifier)
                      .updateThemeMode(val!);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: const Text('深色模式'),
                value: 'dark',
                groupValue: mode,
                onChanged: (val) {
                  ref
                      .read(themeModeNotifierProvider.notifier)
                      .updateThemeMode(val!);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

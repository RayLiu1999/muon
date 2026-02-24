import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:muon/core/constants/app_constants.dart';
import 'package:muon/presentation/providers/settings_provider.dart';
import 'package:muon/presentation/providers/sleep_timer_provider.dart';

/// 計算快取大小的 Provider
final cacheSizeProvider = FutureProvider.autoDispose<String>((ref) async {
  int totalBytes = 0;
  try {
    final tempDir = await getTemporaryDirectory();
    if (tempDir.existsSync()) {
      tempDir.listSync(recursive: true, followLinks: false).forEach((entity) {
        if (entity is File) {
          totalBytes += entity.lengthSync();
        }
      });
    }
  } catch (_) {}

  if (totalBytes < 1024) return '$totalBytes B';
  if (totalBytes < 1024 * 1024)
    return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
  return '${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
});

/// 設定頁
///
/// 提供 App 版本資訊、清除快取、關於等功能。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cacheSizeAsync = ref.watch(cacheSizeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // 外觀設定
          _buildSectionHeader(theme, '外觀'),
          const _ThemeModeTile(),
          const Divider(height: 1),

          // 下載設定
          _buildSectionHeader(theme, '下載設定'),
          const _AudioQualityTile(),
          const _DownloadFormatTile(),
          const Divider(height: 1),

          // 播放設定
          _buildSectionHeader(theme, '播放設定'),
          const _SleepTimerTile(),
          const Divider(height: 1),

          // 資料管理
          _buildSectionHeader(theme, '資料管理'),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('清除快取'),
            subtitle: Text(
              '包含網路圖片暫存與系統產生的中繼檔案\n${cacheSizeAsync.when(data: (size) => '目前佔用：$size', loading: () => '計算中...', error: (_, __) => '計算失敗')}',
            ),
            isThreeLine: true,
            onTap: () {
              _showClearCacheDialog(context, ref);
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
  void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除快取'),
        content: const Text('確定要清除所有暫存資料嗎？這將不會影響您已下載的音樂。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final tempDir = await getTemporaryDirectory();
                if (tempDir.existsSync()) {
                  tempDir.listSync(recursive: true, followLinks: false).forEach(
                    (entity) {
                      if (entity is File) {
                        entity.deleteSync();
                      }
                    },
                  );
                }
                ref.invalidate(cacheSizeProvider); // 重新計算容量
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('快取已清除')));
                }
              } catch (_) {}
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

    // 根據品質等級顯示對應文字
    String qualityText;
    switch (quality) {
      case 'high':
        qualityText = '高品質 (≤1080p / 128kbps)';
        break;
      case 'medium':
        qualityText = '中品質 (≤720p / 96kbps)';
        break;
      case 'low':
        qualityText = '低品質 (≤480p / 64kbps)';
        break;
      default:
        qualityText = '最高品質 (預設/最大檔案)';
    }

    return ListTile(
      leading: const Icon(Icons.high_quality),
      title: const Text('下載品質'),
      subtitle: Text(qualityText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('選擇品質'),
            children: [
              _qualityRadio(ctx, ref, quality, 'best', '最高品質 (無限制 / 192kbps)'),
              _qualityRadio(
                ctx,
                ref,
                quality,
                'high',
                '高品質 (≤1080p / 128kbps)',
              ),
              _qualityRadio(
                ctx,
                ref,
                quality,
                'medium',
                '中品質 (≤720p / 96kbps)',
              ),
              _qualityRadio(
                ctx,
                ref,
                quality,
                'low',
                '低品質 (≤480p / 64kbps・適合直播)',
              ),
            ],
          ),
        );
      },
    );
  }

  /// 建立品質選項 RadioListTile
  Widget _qualityRadio(
    BuildContext ctx,
    WidgetRef ref,
    String groupValue,
    String value,
    String label,
  ) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (val) {
        ref.read(audioQualityProvider.notifier).updateQuality(val!);
        Navigator.pop(ctx);
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

/// 睡眠定時設定
class _SleepTimerTile extends ConsumerWidget {
  const _SleepTimerTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(sleepTimerProvider);
    final isActive = remaining != null;

    // 格式化剩餘時間
    String subtitle;
    if (isActive) {
      final minutes = remaining ~/ 60;
      final seconds = remaining % 60;
      subtitle = '剩餘 $minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      subtitle = '關閉';
    }

    return ListTile(
      leading: const Icon(Icons.bedtime),
      title: const Text('睡眠定時'),
      subtitle: Text(subtitle),
      trailing: isActive
          ? IconButton(
              icon: const Icon(Icons.close),
              tooltip: '取消定時',
              onPressed: () {
                ref.read(sleepTimerProvider.notifier).cancel();
              },
            )
          : const Icon(Icons.chevron_right),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('設定睡眠定時'),
            children: [
              _timerOption(ctx, ref, '關閉', null),
              _timerOption(ctx, ref, '15 分鐘', 15),
              _timerOption(ctx, ref, '30 分鐘', 30),
              _timerOption(ctx, ref, '45 分鐘', 45),
              _timerOption(ctx, ref, '60 分鐘', 60),
              _timerOption(ctx, ref, '90 分鐘', 90),
            ],
          ),
        );
      },
    );
  }

  /// 建立定時選項
  Widget _timerOption(
    BuildContext ctx,
    WidgetRef ref,
    String label,
    int? minutes,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        if (minutes == null) {
          ref.read(sleepTimerProvider.notifier).cancel();
        } else {
          ref.read(sleepTimerProvider.notifier).start(minutes);
        }
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label),
      ),
    );
  }
}

import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:muon/core/utils/duration_formatter.dart';
import 'package:muon/presentation/providers/audio_provider.dart';
import 'package:muon/presentation/providers/media_provider.dart';
import 'package:muon/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:muon/presentation/widgets/media_action_sheet.dart';
import 'package:muon/presentation/pages/player/video_player_page.dart';

/// 全螢幕播放器頁面
class FullScreenPlayerPage extends ConsumerWidget {
  const FullScreenPlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItem = ref.watch(currentMediaItemProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('播放中', style: TextStyle(fontSize: 14)),
        centerTitle: true,
        actions: [
          currentItem.when(
            data: (item) {
              if (item == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  final mediaList =
                      ref.read(allMediaItemsProvider).valueOrNull ?? [];
                  final muonItem = mediaList
                      .where((e) => e.id == item.id)
                      .firstOrNull;
                  if (muonItem != null) {
                    showMediaActionSheet(context, ref, muonItem);
                  } else {
                    // 如果找不到對應實體資料，退回基本的加入清單功能
                    showAddToPlaylistSheet(context, [item.id]);
                  }
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: currentItem.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text('沒有正在播放的曲目'));
          }
          return _buildPlayerContent(context, ref, item, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('載入失敗')),
      ),
    );
  }

  Widget _buildPlayerContent(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    ThemeData theme,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),

              // 封面圖（限制最大高度，避免橫向模式佔滿）
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: _buildCoverArt(context, item, theme),
              ),

              const SizedBox(height: 24),

              // 標題 + 頻道
              _buildSongInfo(item, theme),

              const SizedBox(height: 20),

              // 進度條
              _buildSeekBar(ref, theme),

              const SizedBox(height: 12),

              // 播放控制列
              _buildControls(ref, theme),

              const SizedBox(height: 12),

              // 模式切換列
              _buildModeControls(ref, theme),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 封面圖
  Widget _buildCoverArt(BuildContext context, MediaItem item, ThemeData theme) {
    Widget imageWidget;
    if (item.artUri != null) {
      final uriStr = item.artUri.toString();
      if (uriStr.startsWith('http')) {
        imageWidget = CachedNetworkImage(
          imageUrl: uriStr,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorWidget: (_, __, ___) => Icon(
            Icons.music_note,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
        );
      } else {
        imageWidget = Image.file(
          File(item.artUri!.toFilePath()),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Icon(
            Icons.music_note,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
        );
      }
    } else {
      imageWidget = Icon(
        Icons.music_note,
        size: 80,
        color: theme.colorScheme.primary.withValues(alpha: 0.6),
      );
    }

    // 檢查是否有對應的 mp4 實體檔案可供觀看
    bool hasVideo = false;
    String? expectedVideoPath;
    if (item.extras?['filePath'] != null) {
      final audioPath = item.extras!['filePath'] as String;
      if (audioPath.isNotEmpty) {
        final lastDot = audioPath.lastIndexOf('.');
        if (lastDot > 0) {
          final ext = audioPath.substring(lastDot).toLowerCase();
          expectedVideoPath = ext == '.mp4'
              ? audioPath
              : '${audioPath.substring(0, lastDot)}.mp4';
          if (File(expectedVideoPath).existsSync()) {
            hasVideo = true;
          }
        }
      }
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageWidget,
            ),
          ),
          // 影片疊加層
          if (hasVideo && expectedVideoPath != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    if (expectedVideoPath != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerPage(
                            videoPath: expectedVideoPath!,
                            title: item.title,
                          ),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.video_file, color: Colors.white, size: 20),
                        SizedBox(width: 4),
                        Text(
                          '觀看影片',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 曲目資訊
  Widget _buildSongInfo(MediaItem item, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          height: 30, // 給定一個固定高度給 Marquee
          child: Marquee(
            text: item.title,
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 40.0,
            velocity: 30.0,
            pauseAfterRound: const Duration(seconds: 2),
            startPadding: 0.0,
            accelerationDuration: const Duration(milliseconds: 500),
            accelerationCurve: Curves.easeIn,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.artist ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// 進度條 + 時間
  Widget _buildSeekBar(WidgetRef ref, ThemeData theme) {
    final position = ref.watch(currentPositionProvider);
    final duration = ref.watch(currentDurationProvider);
    final handler = ref.read(audioHandlerProvider);

    final posValue = position.valueOrNull ?? Duration.zero;
    final durValue = duration.valueOrNull ?? Duration.zero;

    final maxValue = durValue.inMilliseconds > 0
        ? durValue.inMilliseconds.toDouble()
        : 1.0;
    final currentValue = posValue.inMilliseconds.toDouble().clamp(
      0.0,
      maxValue,
    );

    return Column(
      children: [
        Slider(
          value: currentValue,
          min: 0,
          max: maxValue,
          onChanged: (value) {
            handler.seek(Duration(milliseconds: value.toInt()));
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DurationFormatter.format(posValue),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                DurationFormatter.format(durValue),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 播放控制列
  Widget _buildControls(WidgetRef ref, ThemeData theme) {
    final playbackState = ref.watch(playbackStateProvider);
    final isPlaying = playbackState.valueOrNull?.playing ?? false;
    final handler = ref.read(audioHandlerProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 上一首
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 36),
          onPressed: () => handler.skipToPrevious(),
        ),
        const SizedBox(width: 16),
        // 播放/暫停
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 36,
              color: theme.colorScheme.onPrimary,
            ),
            onPressed: () {
              if (isPlaying) {
                handler.pause();
              } else {
                handler.play();
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        // 下一首
        IconButton(
          icon: const Icon(Icons.skip_next, size: 36),
          onPressed: () => handler.skipToNext(),
        ),
      ],
    );
  }

  /// 模式切換列（循環 + 隨機）
  Widget _buildModeControls(WidgetRef ref, ThemeData theme) {
    final loopMode = ref.watch(loopModeProvider);
    final shuffleMode = ref.watch(shuffleModeProvider);
    final handler = ref.read(audioHandlerProvider);

    final currentLoop = loopMode.valueOrNull ?? LoopMode.off;
    final isShuffle = shuffleMode.valueOrNull ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 循環模式
        IconButton(
          icon: Icon(
            currentLoop == LoopMode.one ? Icons.repeat_one : Icons.repeat,
            color: currentLoop != LoopMode.off
                ? theme.colorScheme.primary
                : null,
          ),
          onPressed: () => handler.cycleLoopMode(),
        ),
        const SizedBox(width: 32),
        // 隨機播放
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: isShuffle ? theme.colorScheme.primary : null,
          ),
          onPressed: () => handler.toggleShuffle(),
        ),
      ],
    );
  }
}

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muon/core/utils/duration_formatter.dart';
import 'package:muon/presentation/providers/audio_provider.dart';

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
        child: Column(
          children: [
            const Spacer(flex: 1),

            // 封面圖
            _buildCoverArt(theme),

            const SizedBox(height: 32),

            // 標題 + 頻道
            _buildSongInfo(item, theme),

            const SizedBox(height: 24),

            // 進度條
            _buildSeekBar(ref, theme),

            const SizedBox(height: 16),

            // 播放控制列
            _buildControls(ref, theme),

            const SizedBox(height: 16),

            // 模式切換列
            _buildModeControls(ref, theme),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  /// 封面圖
  Widget _buildCoverArt(ThemeData theme) {
    return Container(
      width: 280,
      height: 280,
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
      child: Icon(
        Icons.music_note,
        size: 80,
        color: theme.colorScheme.primary.withValues(alpha: 0.6),
      ),
    );
  }

  /// 曲目資訊
  Widget _buildSongInfo(MediaItem item, ThemeData theme) {
    return Column(
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
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
    final currentValue =
        posValue.inMilliseconds.toDouble().clamp(0.0, maxValue);

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
            currentLoop == LoopMode.one
                ? Icons.repeat_one
                : Icons.repeat,
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

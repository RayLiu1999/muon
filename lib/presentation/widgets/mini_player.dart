import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muon/audio/audio_handler.dart';
import 'package:muon/presentation/widgets/auto_scroll_text.dart';
import 'package:muon/presentation/pages/player/full_screen_player_page.dart';
import 'package:muon/presentation/providers/audio_provider.dart';

/// Mini Player — 全域 persistent
///
/// 顯示在底部導航列上方，點擊展開全螢幕播放器。
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItem = ref.watch(currentMediaItemProvider);
    final playbackState = ref.watch(playbackStateProvider);

    return currentItem.when(
      data: (item) {
        if (item == null) return const SizedBox.shrink();
        return _buildMiniPlayer(context, ref, item, playbackState);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMiniPlayer(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    AsyncValue<PlaybackState> playbackState,
  ) {
    final theme = Theme.of(context);
    final isPlaying = playbackState.valueOrNull?.playing ?? false;
    final handler = ref.read(audioHandlerProvider);

    return GestureDetector(
      onTap: () {
        // Phase 6：開啟全螢幕播放器
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FullScreenPlayerPage()));
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // 進度條
            _buildProgressBar(ref, theme),
            // 主要內容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // 縮圖
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 71, // 16:9 比例 (40 * 16 / 9 ≈ 71)
                        height: 40,
                        child: _buildCoverArt(item, theme),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 標題 + 頻道
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 20,
                            child: AutoScrollText(
                              text: item.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          Text(
                            item.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 播放控制按鈕
                    if (Platform.isMacOS) ..._buildMacOSControls(ref, handler, isPlaying, theme)
                    else _buildPlayPauseButton(handler, isPlaying),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 播放/暫停按鈕（手機版）
  Widget _buildPlayPauseButton(AppAudioHandler handler, bool isPlaying) {
    return IconButton(
      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 28),
      onPressed: () => isPlaying ? handler.pause() : handler.play(),
    );
  }

  /// macOS 完整傳輸控制列：隨機 | 上一首 | 播放/暫停 | 下一首 | 循環
  List<Widget> _buildMacOSControls(
    WidgetRef ref,
    AppAudioHandler handler,
    bool isPlaying,
    ThemeData theme,
  ) {
    final loopMode = ref.watch(loopModeProvider).valueOrNull ?? LoopMode.off;
    final shuffle = ref.watch(shuffleModeProvider).valueOrNull ?? false;

    // 隨機播放圖示顏色：啟用時用 primary
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.iconTheme.color;

    // 循環圖示
    final (loopIcon, loopActive) = switch (loopMode) {
      LoopMode.all  => (Icons.repeat, true),
      LoopMode.one  => (Icons.repeat_one, true),
      _             => (Icons.repeat, false),
    };

    return [
      // 隨機
      IconButton(
        icon: Icon(Icons.shuffle, size: 22,
            color: shuffle ? activeColor : inactiveColor),
        tooltip: '隨機播放',
        onPressed: () => handler.toggleShuffle(),
      ),
      // 上一首
      IconButton(
        icon: const Icon(Icons.skip_previous, size: 26),
        tooltip: '上一首',
        onPressed: () => handler.skipToPrevious(),
      ),
      // 播放/暫停
      IconButton(
        icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 34),
        onPressed: () => isPlaying ? handler.pause() : handler.play(),
      ),
      // 下一首
      IconButton(
        icon: const Icon(Icons.skip_next, size: 26),
        tooltip: '下一首',
        onPressed: () => handler.skipToNext(),
      ),
      // 循環
      IconButton(
        icon: Icon(loopIcon, size: 22,
            color: loopActive ? activeColor : inactiveColor),
        tooltip: loopMode == LoopMode.one ? '單曲循環' : '循環播放',
        onPressed: () => handler.cycleLoopMode(),
      ),
    ];
  }

  /// 進度條（薄型）
  Widget _buildProgressBar(WidgetRef ref, ThemeData theme) {
    final position = ref.watch(currentPositionProvider);
    final duration = ref.watch(currentDurationProvider);

    final posValue = position.valueOrNull ?? Duration.zero;
    final durValue = duration.valueOrNull ?? Duration.zero;

    final progress = durValue.inMilliseconds > 0
        ? posValue.inMilliseconds / durValue.inMilliseconds
        : 0.0;

    return LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0),
      minHeight: 2,
      backgroundColor: Colors.transparent,
      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
    );
  }

  /// 封面圖（支援網路圖片或本地檔案）
  Widget _buildCoverArt(MediaItem item, ThemeData theme) {
    if (item.artUri == null) {
      return Container(
        color: theme.colorScheme.primary.withValues(alpha: 0.2),
        child: const Icon(Icons.music_note, size: 20),
      );
    }

    final uriStr = item.artUri.toString();
    if (uriStr.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: uriStr,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: const Icon(Icons.music_note, size: 20),
        ),
      );
    } else {
      return Image.file(
        File(item.artUri!.toFilePath()),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: const Icon(Icons.music_note, size: 20),
        ),
      );
    }
  }
}

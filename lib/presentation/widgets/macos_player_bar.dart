import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muon/audio/audio_handler.dart';
import 'package:muon/presentation/providers/audio_provider.dart';
import 'package:muon/presentation/widgets/auto_scroll_text.dart';

/// macOS Spotify 風格底部播放列
///
/// 三欄佈局：左（封面 + 歌名）| 中（控制 + 進度條）| 右（音量）
class MacOSPlayerBar extends ConsumerStatefulWidget {
  const MacOSPlayerBar({super.key});

  @override
  ConsumerState<MacOSPlayerBar> createState() => _MacOSPlayerBarState();
}

class _MacOSPlayerBarState extends ConsumerState<MacOSPlayerBar> {
  // 拖拉進度條時的暫存值（避免跳動）
  double? _draggingValue;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = ref.watch(currentMediaItemProvider);
    final theme = Theme.of(context);

    return currentItem.when(
      data: (item) {
        if (item == null) return const SizedBox(height: 80);
        return _buildBar(context, item, theme);
      },
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox(height: 80),
    );
  }

  Widget _buildBar(BuildContext context, MediaItem item, ThemeData theme) {
    final playbackState = ref.watch(playbackStateProvider);
    final isPlaying = playbackState.valueOrNull?.playing ?? false;
    final handler = ref.read(audioHandlerProvider);

    final barColor = theme.colorScheme.surface;
    final borderColor = theme.dividerColor;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: barColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── 左欄：封面 + 歌名歌手 ───────────────────────────
          Expanded(
            flex: 3,
            child: _buildLeftColumn(context, item, theme),
          ),
          // ── 中欄：控制 + 進度條 ──────────────────────────────
          Expanded(
            flex: 4,
            child: _buildCenterColumn(context, handler, isPlaying, theme),
          ),
          // ── 右欄：音量 ──────────────────────────────────────
          Expanded(
            flex: 3,
            child: _buildRightColumn(context, handler, theme),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 左欄：封面 + 歌名 + 歌手
  // ─────────────────────────────────────────────
  Widget _buildLeftColumn(
      BuildContext context, MediaItem item, ThemeData theme) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/player'),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // 封面
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _buildCoverArt(item, theme),
              ),
            ),
            const SizedBox(width: 12),
            // 歌名 + 歌手
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                    child: AutoScrollText(
                      text: item.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.artist ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // ─────────────────────────────────────────────
  // 中欄：傳輸控制 + 進度條
  // ─────────────────────────────────────────────
  Widget _buildCenterColumn(
    BuildContext context,
    AppAudioHandler handler,
    bool isPlaying,
    ThemeData theme,
  ) {
    final loopMode = ref.watch(loopModeProvider).valueOrNull ?? LoopMode.off;
    final shuffle = ref.watch(shuffleModeProvider).valueOrNull ?? false;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.iconTheme.color;

    final (loopIcon, loopActive) = switch (loopMode) {
      LoopMode.all => (Icons.repeat, true),
      LoopMode.one => (Icons.repeat_one, true),
      _ => (Icons.repeat, false),
    };

    return Column(
      children: [
        // 控制按鈕列（在 progress bar 上方空間內垂直置中）
        Expanded(
          child: Align(
            alignment: const Alignment(0, 0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 隨機
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.shuffle,
                      size: 20, color: shuffle ? activeColor : inactiveColor),
                  tooltip: '隨機播放',
                  onPressed: () => handler.toggleShuffle(),
                ),
                const SizedBox(width: 12),
                // 上一首
                IconButton(
                  iconSize: 25,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.skip_previous, size: 25),
                  tooltip: '上一首',
                  onPressed: () => handler.skipToPrevious(),
                ),
                const SizedBox(width: 12),
                // 播放/暫停（大圖示）
                IconButton(
                  iconSize: 40,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 40,
                  ),
                  onPressed: () => isPlaying ? handler.pause() : handler.play(),
                ),
                const SizedBox(width: 12),
                // 下一首
                IconButton(
                  iconSize: 25,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.skip_next, size: 25),
                  tooltip: '下一首',
                  onPressed: () => handler.skipToNext(),
                ),
                const SizedBox(width: 12),
                // 循環
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(loopIcon,
                      size: 20, color: loopActive ? activeColor : inactiveColor),
                  tooltip: loopMode == LoopMode.one ? '單曲循環' : '循環播放',
                  onPressed: () => handler.cycleLoopMode(),
                ),
              ],
            ),
          ),
        ),
        // 進度條列：固定在底部
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildProgressRow(handler, theme),
        ),
      ],
    );
  }

  Widget _buildProgressRow(AppAudioHandler handler, ThemeData theme) {
    final position = ref.watch(currentPositionProvider);
    final duration = ref.watch(currentDurationProvider);

    final posValue = position.valueOrNull ?? Duration.zero;
    final durValue = duration.valueOrNull ?? Duration.zero;

    final maxMs = durValue.inMilliseconds.toDouble();
    final currentMs = posValue.inMilliseconds.toDouble().clamp(0.0, maxMs);
    final sliderValue = _draggingValue ?? (maxMs > 0 ? currentMs / maxMs : 0.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 當前時間
          SizedBox(
            width: 44,
            child: Text(
              _formatDuration(posValue),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
          // 進度滑桿
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: theme.colorScheme.onSurface,
                inactiveTrackColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.25),
                thumbColor: theme.colorScheme.onSurface,
                overlayColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: sliderValue.clamp(0.0, 1.0),
                onChangeStart: (_) => setState(() {}),
                onChanged: (v) => setState(() => _draggingValue = v),
                onChangeEnd: (v) {
                  final target = Duration(
                      milliseconds: (v * maxMs).round());
                  handler.seek(target);
                  setState(() => _draggingValue = null);
                },
              ),
            ),
          ),
          // 總時長
          SizedBox(
            width: 44,
            child: Text(
              _formatDuration(durValue),
              textAlign: TextAlign.left,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 右欄：音量控制
  // ─────────────────────────────────────────────
  Widget _buildRightColumn(
      BuildContext context, AppAudioHandler handler, ThemeData theme) {
    final volumeAsync = ref.watch(volumeProvider);
    final vol = volumeAsync.valueOrNull ?? 1.0;

    IconData volIcon;
    if (vol == 0) {
      volIcon = Icons.volume_off;
    } else if (vol < 0.5) {
      volIcon = Icons.volume_down;
    } else {
      volIcon = Icons.volume_up;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(volIcon, size: 18, color: theme.iconTheme.color),
          const SizedBox(width: 4),
          SizedBox(
            width: 100,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: theme.colorScheme.onSurface,
                inactiveTrackColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.25),
                thumbColor: theme.colorScheme.onSurface,
                overlayColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: vol.clamp(0.0, 1.0),
                onChanged: (v) => handler.setVolume(v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 封面圖
  // ─────────────────────────────────────────────
  Widget _buildCoverArt(MediaItem item, ThemeData theme) {
    final placeholder = Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.2),
      child: const Icon(Icons.music_note, size: 24),
    );

    if (item.artUri == null) return placeholder;

    final uriStr = item.artUri.toString();
    if (uriStr.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: uriStr,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => placeholder,
      );
    } else {
      return Image.file(
        File(item.artUri!.toFilePath()),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }
  }
}

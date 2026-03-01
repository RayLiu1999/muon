import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:muon/core/utils/duration_formatter.dart';
import 'package:muon/presentation/providers/audio_provider.dart';
import 'package:muon/presentation/providers/media_provider.dart';
import 'package:muon/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:muon/presentation/widgets/media_action_sheet.dart';
import 'package:muon/presentation/widgets/auto_scroll_text.dart';

/// 全螢幕播放器頁面
///
/// macOS：封面 ↔ 影片切換，播放控制由底部 PlayerBar 統一管理。
/// 行動版：保留原有的播放控制列。
class FullScreenPlayerPage extends ConsumerStatefulWidget {
  const FullScreenPlayerPage({super.key});

  @override
  ConsumerState<FullScreenPlayerPage> createState() =>
      _FullScreenPlayerPageState();
}

class _FullScreenPlayerPageState extends ConsumerState<FullScreenPlayerPage> {
  // ── macOS 影片模式狀態 ────────────────────────────────────
  bool _showVideo = false;
  VideoPlayerController? _videoController;
  Timer? _syncTimer;

  @override
  void dispose() {
    _syncTimer?.cancel();
    _videoController?.pause();
    _videoController?.dispose();
    super.dispose();
  }

  // ── 計算影片路徑（與音訊同名的 .mp4 檔） ──────────────────
  String? _getVideoPath(MediaItem item) {
    final audioPath = item.extras?['filePath'] as String?;
    if (audioPath == null || audioPath.isEmpty) return null;
    final lastDot = audioPath.lastIndexOf('.');
    if (lastDot <= 0) return null;
    final ext = audioPath.substring(lastDot).toLowerCase();
    final videoPath = ext == '.mp4'
        ? audioPath
        : '${audioPath.substring(0, lastDot)}.mp4';
    return File(videoPath).existsSync() ? videoPath : null;
  }

  // ── 啟動影片模式 ──────────────────────────────────────────
  Future<void> _startVideo(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    _syncTimer?.cancel();
    await _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    if (!mounted) {
      controller.dispose();
      return;
    }

    // 同步至音訊當前進度
    final handler = ref.read(audioHandlerProvider);
    final ps = handler.playbackState.value;
    final elapsed = ps.playing
        ? DateTime.now().difference(ps.updateTime).inMilliseconds
        : 0;
    final audioPos =
        ps.updatePosition + Duration(milliseconds: elapsed.clamp(0, 999999));
    await controller.seekTo(audioPos);
    await controller.setVolume(0); // 靜音，聲音由 audio_handler 輸出
    await controller.play();

    _videoController = controller;
    setState(() => _showVideo = true);

    // 每 800ms 校正影片位置與播放狀態
    _syncTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _syncVideoToAudio();
    });
  }

  // ── 停止影片模式 ──────────────────────────────────────────
  void _stopVideo() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    if (mounted) setState(() => _showVideo = false);
  }

  // ── 每 800ms 將影片位置校正至 audio_handler ──────────────
  void _syncVideoToAudio() {
    final vc = _videoController;
    if (vc == null || !vc.value.isInitialized) return;

    final handler = ref.read(audioHandlerProvider);
    final ps = handler.playbackState.value;
    final elapsed = ps.playing
        ? DateTime.now().difference(ps.updateTime).inMilliseconds
        : 0;
    final audioPos =
        ps.updatePosition + Duration(milliseconds: elapsed.clamp(0, 999999));
    final videoPos = vc.value.position;
    final driftMs = (audioPos - videoPos).abs().inMilliseconds;
    // 誤差超過 1 秒才修正，避免頻繁 seek 造成卡頓
    if (driftMs > 1000) vc.seekTo(audioPos);

    // 同步播放 / 暫停狀態
    if (ps.playing && !vc.value.isPlaying) {
      vc.play();
    } else if (!ps.playing && vc.value.isPlaying) {
      vc.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = ref.watch(currentMediaItemProvider);
    final theme = Theme.of(context);

    // 換曲時自動退出影片模式
    ref.listen(currentMediaItemProvider, (_, __) {
      if (_showVideo) _stopVideo();
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
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
                  final muonItem =
                      mediaList.where((e) => e.id == item.id).firstOrNull;
                  if (muonItem != null) {
                    showMediaActionSheet(context, ref, muonItem);
                  } else {
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
          return Platform.isMacOS
              ? _buildMacOSContent(context, item, theme)
              : _buildMobileContent(context, item, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('載入失敗')),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // macOS 版：封面 ↔ 影片切換（無播放控制，由底部 PlayerBar 統一管理）
  // ─────────────────────────────────────────────────────────
  Widget _buildMacOSContent(
      BuildContext context, MediaItem item, ThemeData theme) {
    final videoPath = _getVideoPath(item);
    final hasVideo = videoPath != null;

    return Column(
      children: [
        // 封面 / 影片切換 pill-tab（有影片時才顯示）
        if (hasVideo)
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 4),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPillTab(
                    context: context,
                    theme: theme,
                    icon: Icons.album_outlined,
                    label: '封面',
                    selected: !_showVideo,
                    onTap: _stopVideo,
                  ),
                  _buildPillTab(
                    context: context,
                    theme: theme,
                    icon: Icons.video_file_outlined,
                    label: '影片',
                    selected: _showVideo,
                    onTap: () => _startVideo(videoPath),
                  ),
                ],
              ),
            ),
          ),
        // 主要顯示區（封面 or 影片）
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            child: _showVideo && _videoController != null
                ? _buildMacOSVideoWidget()
                : _buildMacOSCoverArt(item, theme),
          ),
        ),
        // 曲目資訊（歌名 + 歌手）
        Padding(
          padding: const EdgeInsets.fromLTRB(48, 0, 48, 28),
          child: _buildSongInfo(item, theme),
        ),
      ],
    );
  }

  // 自訂 pill-tab 項目
  Widget _buildPillTab({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // macOS 影片顯示（純畫面，無控制覆層）
  Widget _buildMacOSVideoWidget() {
    final vc = _videoController!;
    if (!vc.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: AspectRatio(
        aspectRatio: vc.value.aspectRatio,
        child: VideoPlayer(vc),
      ),
    );
  }

  // macOS 封面圖（純展示，無按鈕覆層）
  Widget _buildMacOSCoverArt(MediaItem item, ThemeData theme) {
    final placeholder = Icon(
      Icons.music_note,
      size: 80,
      color: theme.colorScheme.primary.withValues(alpha: 0.6),
    );
    Widget imageWidget;
    if (item.artUri != null) {
      final uriStr = item.artUri.toString();
      if (uriStr.startsWith('http')) {
        imageWidget = CachedNetworkImage(
          imageUrl: uriStr,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) => placeholder,
        );
      } else {
        imageWidget = Image.file(
          File(item.artUri!.toFilePath()),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => placeholder,
        );
      }
    } else {
      imageWidget = placeholder;
    }

    return Container(
      decoration: BoxDecoration(
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
    );
  }

  // ─────────────────────────────────────────────────────────
  // 行動版：保留原有佈局（含播放控制）
  // ─────────────────────────────────────────────────────────
  Widget _buildMobileContent(
      BuildContext context, MediaItem item, ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: _buildCoverArt(context, item, theme),
              ),
              const SizedBox(height: 24),
              _buildSongInfo(item, theme),
              const SizedBox(height: 20),
              _buildSeekBar(theme),
              const SizedBox(height: 12),
              _buildControls(theme),
              const SizedBox(height: 12),
              _buildModeControls(theme),
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
                    final path = expectedVideoPath;
                    if (path != null) {
                      context.go('/player/video', extra: {
                        'videoPath': path,
                        'title': item.title,
                      });
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
          child: AutoScrollText(
            text: item.title,
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
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

  /// 進度條 + 時間（行動版）
  Widget _buildSeekBar(ThemeData theme) {
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

  /// 播放控制列（行動版）
  Widget _buildControls(ThemeData theme) {
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

  /// 模式切換列（行動版）
  Widget _buildModeControls(ThemeData theme) {
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

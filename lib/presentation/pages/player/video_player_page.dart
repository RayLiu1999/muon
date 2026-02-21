import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:muon/core/utils/duration_formatter.dart';
import 'package:muon/presentation/providers/audio_provider.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  final String videoPath;
  final String title;

  const VideoPlayerPage({
    super.key,
    required this.videoPath,
    required this.title,
  });

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  VideoPlayerController? _controller;
  bool _showControls = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // 允許橫向與直向旋轉
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initVideo();
  }

  Future<void> _initVideo() async {
    // 進入影片頁面時，暫停背景純音樂播放並釋放 audio session
    // 避免 just_audio 的 AVAudioSession 與 video_player 的 AVPlayer 衝突（iOS 黑屏主因）
    final handler = ref.read(audioHandlerProvider);
    await handler.pause();

    // 先確認檔案存在
    final file = File(widget.videoPath);
    if (!file.existsSync()) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '影片檔案不存在：${widget.videoPath}';
        });
      }
      return;
    }

    try {
      _controller = VideoPlayerController.file(file);

      // 使用 await 確保初始化完成後再執行後續操作
      // iOS 的 AVPlayer 在初始化未完成前無法正確渲染畫面
      await _controller!.initialize();

      if (!mounted) return;

      _controller!.setVolume(1.0);
      await _controller!.play();

      // 監聽播放進度變化以刷新 UI
      _controller!.addListener(_onControllerUpdate);

      if (mounted) {
        setState(() {});
      }

      // 自動隱藏控制列
      _autoHideControls();
    } catch (e) {
      // 捕獲初始化失敗（格式不支援、檔案損壞等）
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '影片載入失敗：$e';
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {}); // 更新進度條
    }
  }

  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls && (_controller?.value.isPlaying ?? false)) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _autoHideControls();
    }
  }

  @override
  void dispose() {
    // 離開時強制改回直向
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _controller?.value.isInitialized ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 影片層
              if (_hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white54,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else if (isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),

              // 控制層
              if (_showControls && !_hasError)
                Container(
                  color: Colors.black45,
                  child: Column(
                    children: [
                      // 頂部導航列
                      _buildTopBar(context),

                      const Spacer(),

                      // 中央播放控制
                      if (isInitialized) _buildCenterControls(),

                      const Spacer(),

                      // 底部進度條
                      if (isInitialized) _buildBottomControls(),
                    ],
                  ),
                ),

              // 錯誤狀態下也顯示返回按鈕
              if (_hasError)
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    final isPlaying = _controller!.value.isPlaying;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 倒轉 10 秒
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 48),
          onPressed: () {
            final position = _controller!.value.position;
            _controller!.seekTo(position - const Duration(seconds: 10));
          },
        ),
        const SizedBox(width: 32),
        // 播放/暫停
        Container(
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 64,
            ),
            onPressed: () {
              if (isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
                _autoHideControls();
              }
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 32),
        // 快轉 10 秒
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 48),
          onPressed: () {
            final position = _controller!.value.position;
            _controller!.seekTo(position + const Duration(seconds: 10));
          },
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: Row(
        children: [
          Text(
            DurationFormatter.format(position),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Expanded(
            child: Slider(
              value: position.inMilliseconds.toDouble(),
              min: 0,
              max: duration.inMilliseconds.toDouble().clamp(
                1.0,
                double.infinity,
              ),
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Colors.white24,
              onChanged: (value) {
                _controller!.seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          Text(
            DurationFormatter.format(duration),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 8),
          // 全螢幕切換按鈕
          IconButton(
            icon: Icon(
              MediaQuery.of(context).orientation == Orientation.portrait
                  ? Icons.fullscreen
                  : Icons.fullscreen_exit,
              color: Colors.white,
            ),
            onPressed: () {
              final isPortrait =
                  MediaQuery.of(context).orientation == Orientation.portrait;
              if (isPortrait) {
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
              } else {
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                ]);
              }
            },
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Muon 音訊處理器
///
/// 整合 just_audio + audio_service，支援：
/// - 本機檔案播放
/// - 背景播放 + 通知列控制
/// - 播放佇列管理
/// - 循環模式 + 隨機播放
class AppAudioHandler extends BaseAudioHandler with SeekHandler, QueueHandler {
  final AudioPlayer _player = AudioPlayer();

  /// 當前播放佇列索引
  int? _currentIndex;

  AppAudioHandler() {
    _initListeners();
  }

  /// 初始化 just_audio 狀態監聽，轉發到 audio_service
  void _initListeners() {
    // 播放狀態變化
    _player.playbackEventStream.listen(_broadcastState);

    // 播放完成時自動播放下一首
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
    });

    // 當前曲目索引變化
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        _currentIndex = index;
        if (index < queue.value.length) {
          mediaItem.add(queue.value[index]);
        }
      }
    });
  }

  /// 將 just_audio 狀態廣播給 audio_service
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _mapProcessingState(_player.processingState),
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  /// 映射 just_audio ProcessingState → audio_service AudioProcessingState
  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// 處理播放完成
  Future<void> _handlePlaybackCompleted() async {
    // 依循環模式決定行為
    if (_player.loopMode == LoopMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (_currentIndex != null &&
        _currentIndex! < queue.value.length - 1) {
      await skipToNext();
    } else if (_player.loopMode == LoopMode.all && queue.value.isNotEmpty) {
      await skipToQueueItem(0);
    } else {
      // 播放結束，停在最後
      await _player.seek(Duration.zero);
      await _player.pause();
    }
  }

  // ========== 播放控制 ==========

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_currentIndex == null || queue.value.isEmpty) return;

    final nextIndex = _currentIndex! + 1;
    if (nextIndex < queue.value.length) {
      await skipToQueueItem(nextIndex);
    } else if (_player.loopMode == LoopMode.all) {
      await skipToQueueItem(0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentIndex == null || queue.value.isEmpty) return;

    // 如果已播放超過 3 秒，回到曲目開頭
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    final prevIndex = _currentIndex! - 1;
    if (prevIndex >= 0) {
      await skipToQueueItem(prevIndex);
    } else if (_player.loopMode == LoopMode.all) {
      await skipToQueueItem(queue.value.length - 1);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;

    _currentIndex = index;
    final item = queue.value[index];
    mediaItem.add(item);

    // 從本機檔案播放
    final filePath = item.extras?['filePath'] as String?;
    if (filePath != null) {
      await _player.setFilePath(filePath);
      await _player.play();
    }
  }

  // ========== 佇列管理 ==========

  /// 載入播放佇列並開始播放指定位置
  Future<void> loadPlaylist(
    List<MediaItem> items, {
    int startIndex = 0,
  }) async {
    queue.add(items);
    if (items.isNotEmpty) {
      await skipToQueueItem(startIndex);
    }
  }

  /// 清空佇列
  Future<void> clearQueue() async {
    await _player.stop();
    queue.add([]);
    _currentIndex = null;
  }

  // ========== 模式控制 ==========

  /// 切換循環模式（none → all → one → none）
  Future<void> cycleLoopMode() async {
    switch (_player.loopMode) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  /// 切換隨機播放
  Future<void> toggleShuffle() async {
    final enabled = !_player.shuffleModeEnabled;
    await _player.setShuffleModeEnabled(enabled);
  }

  // ========== 存取器 ==========

  /// 取得底層 AudioPlayer（提供 stream 給 Provider 使用）
  AudioPlayer get player => _player;

  /// 取得當前循環模式 Stream
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;

  /// 取得隨機播放狀態 Stream
  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;

  /// 取得播放位置 Stream
  Stream<Duration> get positionStream => _player.positionStream;

  /// 取得曲目時長 Stream
  Stream<Duration?> get durationStream => _player.durationStream;

  /// 釋放資源
  Future<void> dispose() async {
    await _player.dispose();
  }
}

import 'dart:async';
import 'dart:io';
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
  ConcatenatingAudioSource? _playlist;
  String? currentCollectionId;

  AppAudioHandler() {
    _initListeners();
  }

  /// 初始化 just_audio 狀態監聽，轉發到 audio_service
  void _initListeners() {
    // 播放狀態變化
    _player.playbackEventStream.listen(_broadcastState);

    // 當前曲目變化
    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null) return;
      final sequence = sequenceState.effectiveSequence;
      if (sequence.isEmpty || sequenceState.currentIndex >= sequence.length)
        return;

      final currentItem = sequence[sequenceState.currentIndex];
      final mediaItemValue = currentItem.tag as MediaItem;
      mediaItem.add(mediaItemValue);
    });
  }

  /// 將 just_audio 狀態廣播給 audio_service
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
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
        queueIndex: event.currentIndex,
      ),
    );
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
  Future<void> skipToNext() async => _player.seekToNext();

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  // ========== 佇列管理 ==========

  /// 載入播放佇列並開始播放指定位置
  Future<void> loadPlaylist(
    List<MediaItem> items, {
    int startIndex = 0,
    String? collectionId,
  }) async {
    currentCollectionId = collectionId;
    queue.add(items);
    if (items.isEmpty) {
      _playlist = null;
      return;
    }

    final audioSources = <AudioSource>[];
    for (final item in items) {
      final filePath = item.extras?['filePath'] as String?;
      if (filePath == null || filePath.isEmpty) continue;

      // 驗證檔案存在，避免 iOS 上載入不存在的檔案導致 -11800
      final file = File(filePath);
      if (!file.existsSync()) {
        print('[AudioHandler] 檔案不存在，跳過：$filePath');
        continue;
      }

      audioSources.add(AudioSource.uri(Uri.file(filePath), tag: item));
    }

    if (audioSources.isEmpty) return;

    _playlist = ConcatenatingAudioSource(children: audioSources);

    try {
      await _player.setAudioSource(
        _playlist!,
        initialIndex: startIndex.clamp(0, audioSources.length - 1),
      );
      await _player.play();
    } catch (e) {
      print('[AudioHandler] 載入播放清單失敗：$e');
    }
  }

  /// 動態加入項目到當前佇列
  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    if (_playlist == null) return;
    final filePath = mediaItem.extras?['filePath'] as String?;
    final audioSource = AudioSource.uri(
      Uri.file(filePath ?? ''),
      tag: mediaItem,
    );

    await _playlist!.add(audioSource);
    final newQueue = List<MediaItem>.from(queue.value)..add(mediaItem);
    queue.add(newQueue);
  }

  /// 動態移除當前佇列的項目
  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    if (_playlist == null) return;
    final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    if (index >= 0) {
      await _playlist!.removeAt(index);
      final newQueue = List<MediaItem>.from(queue.value)..removeAt(index);
      queue.add(newQueue);
    }
  }

  /// 清空佇列
  Future<void> clearQueue() async {
    await _player.stop();
    _playlist = null;
    currentCollectionId = null;
    queue.add([]);
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

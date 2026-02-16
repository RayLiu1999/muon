---
name: flutter-audio-service
description: 實作背景音訊播放、通知列控制與 MediaSession。當需要處理播放器核心邏輯、背景播放、通知列或耳機控制時觸發。
---

# Flutter 背景音訊播放（audio_service + just_audio）

## 何時使用

- 實作或修改播放器核心邏輯
- 處理背景播放行為
- 設定 Android 通知列控制
- 處理耳機按鍵 / 藍牙控制
- 管理 Audio Focus

## 架構說明

```
audio_service（系統層介面）
    │
    ├── Android: MediaSession + Foreground Service + 通知列
    ├── iOS: AVAudioSession + Control Center + Lock Screen
    │
    └── AudioHandler（你的實作）
            │
            └── just_audio（實際播放引擎）
```

## 核心實作模式

### AudioHandler 實作

```dart
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// 背景音訊播放處理器
class AppAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AppAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // 監聽播放狀態變化，同步到 MediaSession
    _player.playbackEventStream.listen(_broadcastState);

    // 監聽目前播放項目變化
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  /// 播放指定媒體項目
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
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  /// 載入播放佇列
  Future<void> loadPlaylist(List<MediaItem> items, {int initialIndex = 0}) async {
    // 更新 queue
    queue.add(items);

    // 建立 just_audio 的播放來源
    final audioSources = items.map((item) {
      return AudioSource.file(
        item.extras!['filePath'] as String,
        tag: item,
      );
    }).toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: initialIndex,
    );
  }

  /// 設定循環模式
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
    switch (mode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  /// 設定隨機播放
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    final enabled = mode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(enabled);
  }

  /// 廣播播放狀態（同步到通知列、鎖屏等）
  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      queueIndex: event.currentIndex,
    ));
  }
}
```

### 初始化（在 main.dart）

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 audio_service
  final audioHandler = await AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.offlineyt.audio',
      androidNotificationChannelName: 'OfflineYT 播放',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true, // 暫停時移除前景 service（省電）
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const MyApp(),
    ),
  );
}
```

### MediaItem 轉換（本地檔案 → audio_service MediaItem）

```dart
/// 將本地資料庫的 MediaItem 轉換為 audio_service 的 MediaItem
AudioServiceMediaItem toAudioServiceItem(DbMediaItem dbItem) {
  return MediaItem(
    id: dbItem.id,
    title: dbItem.title,
    artist: dbItem.channel,
    duration: Duration(milliseconds: dbItem.durationMs),
    artUri: Uri.file(dbItem.thumbnailPath),
    extras: {
      'filePath': dbItem.filePath,
      'sourceId': dbItem.sourceId,
      'isVideo': dbItem.isVideo,
    },
  );
}
```

## Android 設定

### AndroidManifest.xml 必要權限

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## 重要提醒

- `AudioHandler` 是全域單例，在 `main()` 初始化一次
- 修改 `AudioHandler` 時必須注意 `playbackState` 的正確廣播，否則通知列會不同步
- `just_audio` 的 `ConcatenatingAudioSource` 支援動態新增/移除曲目
- 使用 `androidStopForegroundOnPause: true` 讓暫停時的通知可被滑掉，節省電量
- 播放本機檔案使用 `AudioSource.file()`，非 `AudioSource.uri()`
- Audio Focus 由 `audio_session` 套件自動管理，通常不需額外設定

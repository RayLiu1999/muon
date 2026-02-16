import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muon/audio/audio_handler.dart';

part 'audio_provider.g.dart';

/// 全域 AudioHandler Provider
///
/// 在 main.dart 中透過 Override 注入 AudioService.init() 回傳的實例。
@Riverpod(keepAlive: true)
AppAudioHandler audioHandler(AudioHandlerRef ref) {
  throw UnimplementedError(
    'audioHandler provider 必須在 ProviderScope 中透過 override 提供實例',
  );
}

/// 播放狀態 Provider（串流）
@riverpod
Stream<PlaybackState> playbackState(PlaybackStateRef ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState;
}

/// 當前播放曲目 Provider（串流）
@riverpod
Stream<MediaItem?> currentMediaItem(CurrentMediaItemRef ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.mediaItem;
}

/// 當前播放位置 Provider（串流）
@riverpod
Stream<Duration> currentPosition(CurrentPositionRef ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.positionStream;
}

/// 當前曲目時長 Provider（串流）
@riverpod
Stream<Duration?> currentDuration(CurrentDurationRef ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.durationStream;
}

/// 當前循環模式 Provider（串流）
@riverpod
Stream<LoopMode> loopMode(LoopModeRef ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.loopModeStream;
}

/// 隨機播放狀態 Provider（串流）
@riverpod
Stream<bool> shuffleMode(ShuffleModeRef ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.shuffleModeStream;
}

/// 播放佇列 Provider（串流）
@riverpod
Stream<List<MediaItem>> playbackQueue(PlaybackQueueRef ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.queue;
}

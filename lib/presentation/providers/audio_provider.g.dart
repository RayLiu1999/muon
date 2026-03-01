// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioHandlerHash() => r'05d3fef81519bc709022a146928948f273b5e47b';

/// 全域 AudioHandler Provider
///
/// 在 main.dart 中透過 Override 注入 AudioService.init() 回傳的實例。
///
/// Copied from [audioHandler].
@ProviderFor(audioHandler)
final audioHandlerProvider = Provider<AppAudioHandler>.internal(
  audioHandler,
  name: r'audioHandlerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioHandlerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioHandlerRef = ProviderRef<AppAudioHandler>;
String _$playbackStateHash() => r'70e04338c5966980fa2b2fd77a8c5614807b786e';

/// 播放狀態 Provider（串流）
///
/// Copied from [playbackState].
@ProviderFor(playbackState)
final playbackStateProvider = AutoDisposeStreamProvider<PlaybackState>.internal(
  playbackState,
  name: r'playbackStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playbackStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlaybackStateRef = AutoDisposeStreamProviderRef<PlaybackState>;
String _$currentMediaItemHash() => r'f22a66d492cadd42a98db129a03a317c8eb7d049';

/// 當前播放曲目 Provider（串流）
///
/// Copied from [currentMediaItem].
@ProviderFor(currentMediaItem)
final currentMediaItemProvider = AutoDisposeStreamProvider<MediaItem?>.internal(
  currentMediaItem,
  name: r'currentMediaItemProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentMediaItemHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentMediaItemRef = AutoDisposeStreamProviderRef<MediaItem?>;
String _$currentPositionHash() => r'4860848e42b5a136e4f51975b746906f0f42f23a';

/// 當前播放位置 Provider（串流）
///
/// Copied from [currentPosition].
@ProviderFor(currentPosition)
final currentPositionProvider = AutoDisposeStreamProvider<Duration>.internal(
  currentPosition,
  name: r'currentPositionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentPositionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentPositionRef = AutoDisposeStreamProviderRef<Duration>;
String _$currentDurationHash() => r'1453f27a6e223a51f056f32e89e69cc87939ad92';

/// 當前曲目時長 Provider（串流）
///
/// Copied from [currentDuration].
@ProviderFor(currentDuration)
final currentDurationProvider = AutoDisposeStreamProvider<Duration?>.internal(
  currentDuration,
  name: r'currentDurationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentDurationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentDurationRef = AutoDisposeStreamProviderRef<Duration?>;
String _$loopModeHash() => r'fc689cfc870ad8d0a28ed38d33eab9a72d099ba9';

/// 當前循環模式 Provider（串流）
///
/// Copied from [loopMode].
@ProviderFor(loopMode)
final loopModeProvider = AutoDisposeStreamProvider<LoopMode>.internal(
  loopMode,
  name: r'loopModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loopModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LoopModeRef = AutoDisposeStreamProviderRef<LoopMode>;
String _$shuffleModeHash() => r'81b754d93df2b2ad1a489b1423604d7630321598';

/// 隨機播放狀態 Provider（串流）
///
/// Copied from [shuffleMode].
@ProviderFor(shuffleMode)
final shuffleModeProvider = AutoDisposeStreamProvider<bool>.internal(
  shuffleMode,
  name: r'shuffleModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shuffleModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShuffleModeRef = AutoDisposeStreamProviderRef<bool>;
String _$playbackQueueHash() => r'7e8b7e7997c4470b9a3818f5d7c4c902296b0ef2';

/// 播放佇列 Provider（串流）
///
/// Copied from [playbackQueue].
@ProviderFor(playbackQueue)
final playbackQueueProvider =
    AutoDisposeStreamProvider<List<MediaItem>>.internal(
      playbackQueue,
      name: r'playbackQueueProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$playbackQueueHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlaybackQueueRef = AutoDisposeStreamProviderRef<List<MediaItem>>;
String _$volumeHash() => r'dbb32568e9b4cad3c51bc564f953072de3dbfd61';

/// 音量 Provider（串流）
///
/// Copied from [volume].
@ProviderFor(volume)
final volumeProvider = AutoDisposeStreamProvider<double>.internal(
  volume,
  name: r'volumeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$volumeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VolumeRef = AutoDisposeStreamProviderRef<double>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

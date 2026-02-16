// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mediaRepositoryHash() => r'fc61da05444a99bbf821b339bfd4c84ece3b97c0';

/// MediaRepository Provider
///
/// Copied from [mediaRepository].
@ProviderFor(mediaRepository)
final mediaRepositoryProvider = Provider<MediaRepository>.internal(
  mediaRepository,
  name: r'mediaRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mediaRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MediaRepositoryRef = ProviderRef<MediaRepository>;
String _$allMediaItemsHash() => r'110534700c249fda96b3071b27a5b19bcbd0faf8';

/// 所有媒體項目 Provider（串流）
///
/// Copied from [allMediaItems].
@ProviderFor(allMediaItems)
final allMediaItemsProvider =
    AutoDisposeStreamProvider<List<MediaItem>>.internal(
      allMediaItems,
      name: r'allMediaItemsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allMediaItemsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllMediaItemsRef = AutoDisposeStreamProviderRef<List<MediaItem>>;
String _$favoriteMediaItemsHash() =>
    r'c92aec49faeb3945c1d26abbc10934cfb4c556cd';

/// 我的最愛 Provider（串流）
///
/// Copied from [favoriteMediaItems].
@ProviderFor(favoriteMediaItems)
final favoriteMediaItemsProvider =
    AutoDisposeStreamProvider<List<MediaItem>>.internal(
      favoriteMediaItems,
      name: r'favoriteMediaItemsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$favoriteMediaItemsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FavoriteMediaItemsRef = AutoDisposeStreamProviderRef<List<MediaItem>>;
String _$recentlyPlayedHash() => r'5e1ff5684b1c743b1317b9e2f7350e9df70b0f71';

/// 最近播放 Provider
///
/// Copied from [recentlyPlayed].
@ProviderFor(recentlyPlayed)
final recentlyPlayedProvider =
    AutoDisposeFutureProvider<List<MediaItem>>.internal(
      recentlyPlayed,
      name: r'recentlyPlayedProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recentlyPlayedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentlyPlayedRef = AutoDisposeFutureProviderRef<List<MediaItem>>;
String _$recentlyDownloadedHash() =>
    r'0bcf40c9731f952ee4dde7cd8af490a3dbcece50';

/// 最近下載 Provider
///
/// Copied from [recentlyDownloaded].
@ProviderFor(recentlyDownloaded)
final recentlyDownloadedProvider =
    AutoDisposeFutureProvider<List<MediaItem>>.internal(
      recentlyDownloaded,
      name: r'recentlyDownloadedProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recentlyDownloadedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentlyDownloadedRef = AutoDisposeFutureProviderRef<List<MediaItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

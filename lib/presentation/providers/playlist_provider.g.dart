// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allPlaylistsHash() => r'03120d0562dc6b665f23615c93f63430445f6418';

/// 所有播放清單 (不含清單內項目)
///
/// Copied from [allPlaylists].
@ProviderFor(allPlaylists)
final allPlaylistsProvider = StreamProvider<List<Playlist>>.internal(
  allPlaylists,
  name: r'allPlaylistsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allPlaylistsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllPlaylistsRef = StreamProviderRef<List<Playlist>>;
String _$playlistMediaItemsHash() =>
    r'1da5d8e041cbf772bc1ec51160d65926319b6a6d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// 某個播放清單內的所有項目
///
/// Copied from [playlistMediaItems].
@ProviderFor(playlistMediaItems)
const playlistMediaItemsProvider = PlaylistMediaItemsFamily();

/// 某個播放清單內的所有項目
///
/// Copied from [playlistMediaItems].
class PlaylistMediaItemsFamily extends Family<AsyncValue<List<MediaItem>>> {
  /// 某個播放清單內的所有項目
  ///
  /// Copied from [playlistMediaItems].
  const PlaylistMediaItemsFamily();

  /// 某個播放清單內的所有項目
  ///
  /// Copied from [playlistMediaItems].
  PlaylistMediaItemsProvider call(String playlistId) {
    return PlaylistMediaItemsProvider(playlistId);
  }

  @override
  PlaylistMediaItemsProvider getProviderOverride(
    covariant PlaylistMediaItemsProvider provider,
  ) {
    return call(provider.playlistId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'playlistMediaItemsProvider';
}

/// 某個播放清單內的所有項目
///
/// Copied from [playlistMediaItems].
class PlaylistMediaItemsProvider
    extends AutoDisposeStreamProvider<List<MediaItem>> {
  /// 某個播放清單內的所有項目
  ///
  /// Copied from [playlistMediaItems].
  PlaylistMediaItemsProvider(String playlistId)
    : this._internal(
        (ref) => playlistMediaItems(ref as PlaylistMediaItemsRef, playlistId),
        from: playlistMediaItemsProvider,
        name: r'playlistMediaItemsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$playlistMediaItemsHash,
        dependencies: PlaylistMediaItemsFamily._dependencies,
        allTransitiveDependencies:
            PlaylistMediaItemsFamily._allTransitiveDependencies,
        playlistId: playlistId,
      );

  PlaylistMediaItemsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.playlistId,
  }) : super.internal();

  final String playlistId;

  @override
  Override overrideWith(
    Stream<List<MediaItem>> Function(PlaylistMediaItemsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PlaylistMediaItemsProvider._internal(
        (ref) => create(ref as PlaylistMediaItemsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        playlistId: playlistId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MediaItem>> createElement() {
    return _PlaylistMediaItemsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PlaylistMediaItemsProvider &&
        other.playlistId == playlistId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, playlistId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PlaylistMediaItemsRef on AutoDisposeStreamProviderRef<List<MediaItem>> {
  /// The parameter `playlistId` of this provider.
  String get playlistId;
}

class _PlaylistMediaItemsProviderElement
    extends AutoDisposeStreamProviderElement<List<MediaItem>>
    with PlaylistMediaItemsRef {
  _PlaylistMediaItemsProviderElement(super.provider);

  @override
  String get playlistId => (origin as PlaylistMediaItemsProvider).playlistId;
}

String _$playlistNotifierHash() => r'5f3ccf1468945f43334b260037b26008a5e40980';

/// 播放清單管理邏輯
///
/// Copied from [PlaylistNotifier].
@ProviderFor(PlaylistNotifier)
final playlistNotifierProvider =
    AutoDisposeNotifierProvider<PlaylistNotifier, void>.internal(
      PlaylistNotifier.new,
      name: r'playlistNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$playlistNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PlaylistNotifier = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

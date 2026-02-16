// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$youtubeSearchServiceHash() =>
    r'beb2d4ca2aaf03e9e9cf9e2db3085fc8dfdfd272';

/// YouTube 搜尋服務 Provider
///
/// Copied from [youtubeSearchService].
@ProviderFor(youtubeSearchService)
final youtubeSearchServiceProvider = Provider<YouTubeSearchService>.internal(
  youtubeSearchService,
  name: r'youtubeSearchServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$youtubeSearchServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef YoutubeSearchServiceRef = ProviderRef<YouTubeSearchService>;
String _$searchNotifierHash() => r'16015e77a65956199bd653fc84cf5d3f0180c302';

/// 搜尋結果 Provider
///
/// Copied from [SearchNotifier].
@ProviderFor(SearchNotifier)
final searchNotifierProvider =
    AutoDisposeNotifierProvider<
      SearchNotifier,
      AsyncValue<List<SearchResult>>
    >.internal(
      SearchNotifier.new,
      name: r'searchNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchNotifier = AutoDisposeNotifier<AsyncValue<List<SearchResult>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

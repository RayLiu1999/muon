// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$downloadServiceHash() => r'0a6f43374612b0bf6306c053c31eaf76f9fea9e8';

/// 下載服務 Provider
///
/// Copied from [downloadService].
@ProviderFor(downloadService)
final downloadServiceProvider = Provider<DownloadService>.internal(
  downloadService,
  name: r'downloadServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$downloadServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DownloadServiceRef = ProviderRef<DownloadService>;
String _$downloadTasksHash() => r'4fdf098998376a550684c57ef2779471ee2cd46f';

/// 下載任務列表 Provider（串流）
///
/// Copied from [downloadTasks].
@ProviderFor(downloadTasks)
final downloadTasksProvider =
    AutoDisposeStreamProvider<List<DownloadTask>>.internal(
      downloadTasks,
      name: r'downloadTasksProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$downloadTasksHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DownloadTasksRef = AutoDisposeStreamProviderRef<List<DownloadTask>>;
String _$downloadNotifierHash() => r'f5867732a582667f32c3c10216c7c68f04381feb';

/// 下載控制 Notifier
///
/// Copied from [DownloadNotifier].
@ProviderFor(DownloadNotifier)
final downloadNotifierProvider =
    AutoDisposeNotifierProvider<DownloadNotifier, Map<String, double>>.internal(
      DownloadNotifier.new,
      name: r'downloadNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$downloadNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DownloadNotifier = AutoDisposeNotifier<Map<String, double>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

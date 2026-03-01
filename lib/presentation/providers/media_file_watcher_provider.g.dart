// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_file_watcher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mediaFileWatcherHash() => r'6c0f9123ecd2c7df73944badb91e4074b19cb550';

/// macOS 檔案系統監聽器
///
/// 監聽下載目錄（預設及使用者自訂），當外部程式刪除音訊檔案時，
/// 自動從資料庫中移除對應的媒體記錄，保持媒體庫與磁碟狀態同步。
/// 非 macOS 平台為 no-op。
///
/// Copied from [MediaFileWatcher].
@ProviderFor(MediaFileWatcher)
final mediaFileWatcherProvider =
    NotifierProvider<MediaFileWatcher, void>.internal(
      MediaFileWatcher.new,
      name: r'mediaFileWatcherProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$mediaFileWatcherHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MediaFileWatcher = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

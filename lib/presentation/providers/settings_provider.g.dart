// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sharedPreferencesHash() => r'57aa468f840b7e52a643eb8cadcb48fb2dba4cee';

/// SharedPreferences Provider
///
/// Copied from [sharedPreferences].
@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = Provider<SharedPreferences>.internal(
  sharedPreferences,
  name: r'sharedPreferencesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sharedPreferencesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SharedPreferencesRef = ProviderRef<SharedPreferences>;
String _$audioQualityHash() => r'd15eaf5afc8665701c43c659142ca3cce2e1ca27';

/// 音質設定 Provider
///
/// Copied from [AudioQuality].
@ProviderFor(AudioQuality)
final audioQualityProvider = NotifierProvider<AudioQuality, String>.internal(
  AudioQuality.new,
  name: r'audioQualityProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioQualityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AudioQuality = Notifier<String>;
String _$downloadFormatHash() => r'86f6fbd770b62ac140c55a66f0b9e5fed9adeff4';

/// 下載格式設定 Provider
///
/// Copied from [DownloadFormat].
@ProviderFor(DownloadFormat)
final downloadFormatProvider =
    NotifierProvider<DownloadFormat, String>.internal(
      DownloadFormat.new,
      name: r'downloadFormatProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$downloadFormatHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DownloadFormat = Notifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

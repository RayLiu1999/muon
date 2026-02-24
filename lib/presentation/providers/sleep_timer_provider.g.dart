// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_timer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sleepTimerHash() => r'c5df5ca4c86500ffaef0db286a4de1c20597b30a';

/// 睡眠定時狀態
///
/// 儲存剩餘秒數。null 表示未啟用定時器，0 表示時間到。
///
/// Copied from [SleepTimer].
@ProviderFor(SleepTimer)
final sleepTimerProvider = NotifierProvider<SleepTimer, int?>.internal(
  SleepTimer.new,
  name: r'sleepTimerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sleepTimerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SleepTimer = Notifier<int?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

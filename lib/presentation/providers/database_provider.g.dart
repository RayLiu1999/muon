// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseHash() => r'87a458f7f7794ffb7821ac2eacfce4e5557ac540';

/// 全域資料庫 Provider
///
/// 在 main.dart 中透過 Override 注入實際的 AppDatabase 實例。
/// 測試中可透過 ProviderScope.overrides 注入 in-memory 資料庫。
///
/// Copied from [database].
@ProviderFor(database)
final databaseProvider = Provider<AppDatabase>.internal(
  database,
  name: r'databaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$databaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DatabaseRef = ProviderRef<AppDatabase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

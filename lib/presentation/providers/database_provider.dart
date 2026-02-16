import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muon/data/database/app_database.dart';

part 'database_provider.g.dart';

/// 全域資料庫 Provider
///
/// 在 main.dart 中透過 Override 注入實際的 AppDatabase 實例。
/// 測試中可透過 ProviderScope.overrides 注入 in-memory 資料庫。
@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  throw UnimplementedError(
    'database provider 必須在 ProviderScope 中透過 override 提供實例',
  );
}

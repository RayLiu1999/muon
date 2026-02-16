import 'package:drift/native.dart';
import 'package:muon/data/database/app_database.dart';

/// 建立 in-memory drift 資料庫（測試專用）
///
/// 每次呼叫會建立一個全新的空資料庫，測試結束後應呼叫 close()。
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

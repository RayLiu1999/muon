import 'package:drift/drift.dart';

/// 播放清單資料表
class Playlists extends Table {
  /// UUID 主鍵
  TextColumn get id => text()();

  /// 清單名稱
  TextColumn get name => text()();

  /// 類型：'system'（系統清單，不可刪除）/ 'user'（使用者清單）
  TextColumn get type => text().withDefault(const Constant('user'))();

  /// 封面路徑（可為 null）
  TextColumn get coverPath => text().nullable()();

  /// 建立時間
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// 最後更新時間
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

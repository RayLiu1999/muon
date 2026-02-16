import 'package:drift/drift.dart';

/// 下載任務資料表
class DownloadTasks extends Table {
  /// UUID 主鍵
  TextColumn get id => text()();

  /// YouTube video ID
  TextColumn get sourceId => text()();

  /// 影片標題
  TextColumn get title => text()();

  /// 縮圖 URL（可為 null）
  TextColumn get thumbnailUrl => text().nullable()();

  /// 狀態：queued / downloading / paused / completed / failed
  TextColumn get status =>
      text().withDefault(const Constant('queued'))();

  /// 下載進度（0.0 ~ 1.0）
  RealColumn get progress =>
      real().withDefault(const Constant(0.0))();

  /// 目標檔案路徑（可為 null，下載完成後才有）
  TextColumn get filePath => text().nullable()();

  /// 格式：audio / video
  TextColumn get format =>
      text().withDefault(const Constant('audio'))();

  /// 失敗原因（可為 null）
  TextColumn get errorMessage => text().nullable()();

  /// 建立時間
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

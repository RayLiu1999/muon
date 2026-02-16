import 'package:drift/drift.dart';

/// 媒體項目資料表
///
/// 儲存已下載的音訊/影片檔案的元資料。
class MediaItems extends Table {
  /// App 內部 UUID 主鍵
  TextColumn get id => text()();

  /// YouTube 影片 ID
  TextColumn get sourceId => text()();

  /// 標題
  TextColumn get title => text()();

  /// 頻道名稱
  TextColumn get channel => text()();

  /// 時長（毫秒）
  IntColumn get durationMs => integer()();

  /// 本機檔案路徑
  TextColumn get filePath => text()();

  /// 縮圖本機快取路徑
  TextColumn get thumbnailPath => text()();

  /// 檔案大小（bytes）
  IntColumn get fileSize => integer().withDefault(const Constant(0))();

  /// 是否為影片
  BoolColumn get isVideo => boolean().withDefault(const Constant(false))();

  /// 是否為我的最愛
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();

  /// 下載時間
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// 最後播放時間
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();

  /// 播放次數
  IntColumn get playCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

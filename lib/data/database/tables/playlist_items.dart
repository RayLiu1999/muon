import 'package:drift/drift.dart';
import 'media_items.dart';
import 'playlists.dart';

/// 播放清單項目關聯表（多對多）
class PlaylistItems extends Table {
  /// UUID 主鍵
  TextColumn get id => text()();

  /// 對應 Playlist.id（外鍵）
  TextColumn get playlistId =>
      text().references(Playlists, #id)();

  /// 對應 MediaItem.id（外鍵）
  TextColumn get mediaItemId =>
      text().references(MediaItems, #id)();

  /// 排序位置（拖拉排序用）
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 加入時間
  DateTimeColumn get addedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

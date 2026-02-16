import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/media_items.dart';

part 'media_dao.g.dart';

/// 媒體項目 DAO — 處理 MediaItems 表的 CRUD 操作
@DriftAccessor(tables: [MediaItems])
class MediaDao extends DatabaseAccessor<AppDatabase> with _$MediaDaoMixin {
  MediaDao(AppDatabase db) : super(db);

  /// 取得所有媒體項目（依建立時間降冪排列）
  Future<List<MediaItem>> getAllMediaItems() {
    return (select(mediaItems)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 監聽所有媒體項目變化（即時更新 UI）
  Stream<List<MediaItem>> watchAllMediaItems() {
    return (select(mediaItems)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// 依 ID 查詢單一媒體項目
  Future<MediaItem?> findById(String id) {
    return (select(mediaItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 依 YouTube sourceId 查詢（檢查是否已下載）
  Future<MediaItem?> findBySourceId(String sourceId) {
    return (select(mediaItems)..where((t) => t.sourceId.equals(sourceId)))
        .getSingleOrNull();
  }

  /// 取得我的最愛列表
  Future<List<MediaItem>> getFavorites() {
    return (select(mediaItems)
          ..where((t) => t.favorite.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)]))
        .get();
  }

  /// 監聽我的最愛列表
  Stream<List<MediaItem>> watchFavorites() {
    return (select(mediaItems)
          ..where((t) => t.favorite.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)]))
        .watch();
  }

  /// 取得最近播放列表（限制數量）
  Future<List<MediaItem>> getRecentlyPlayed({int limit = 20}) {
    return (select(mediaItems)
          ..where((t) => t.lastPlayedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
          ..limit(limit))
        .get();
  }

  /// 取得最近下載列表（限制數量）
  Future<List<MediaItem>> getRecentlyDownloaded({int limit = 20}) {
    return (select(mediaItems)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 新增媒體項目
  Future<void> insertMediaItem(MediaItemsCompanion item) {
    return into(mediaItems).insert(item);
  }

  /// 切換我的最愛
  Future<void> toggleFavorite(String id, bool isFavorite) {
    return (update(mediaItems)..where((t) => t.id.equals(id)))
        .write(MediaItemsCompanion(favorite: Value(isFavorite)));
  }

  /// 更新播放記錄（累加播放次數 + 更新最後播放時間）
  Future<void> updatePlayRecord(String id) async {
    final item = await findById(id);
    if (item == null) return;

    await (update(mediaItems)..where((t) => t.id.equals(id))).write(
      MediaItemsCompanion(
        lastPlayedAt: Value(DateTime.now()),
        playCount: Value(item.playCount + 1),
      ),
    );
  }

  /// 刪除媒體項目
  Future<int> deleteMediaItem(String id) {
    return (delete(mediaItems)..where((t) => t.id.equals(id))).go();
  }

  /// 本地搜尋（依標題或頻道名稱模糊搜尋）
  Future<List<MediaItem>> search(String query) {
    final pattern = '%$query%';
    return (select(mediaItems)
          ..where(
            (t) => t.title.like(pattern) | t.channel.like(pattern),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }
}

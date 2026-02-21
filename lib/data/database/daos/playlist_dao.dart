import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/playlists.dart';
import '../tables/playlist_items.dart';
import '../tables/media_items.dart';
import 'media_dao.dart';

part 'playlist_dao.g.dart';

/// 播放清單 DAO — 處理 Playlists 與 PlaylistItems 的操作
@DriftAccessor(tables: [Playlists, PlaylistItems, MediaItems])
class PlaylistDao extends DatabaseAccessor<AppDatabase>
    with _$PlaylistDaoMixin {
  PlaylistDao(AppDatabase db) : super(db);

  /// 取得所有播放清單
  Future<List<Playlist>> getAllPlaylists() {
    return (select(
      playlists,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
  }

  /// 監聽所有播放清單
  Stream<List<Playlist>> watchAllPlaylists() {
    return (select(
      playlists,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();
  }

  /// 依 ID 查詢單一播放清單
  Future<Playlist?> findById(String id) {
    return (select(playlists)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 取得播放清單內的所有媒體項目（支援動態排序）
  Future<List<MediaItem>> getPlaylistMediaItems(
    String playlistId, {
    MediaSortOption? sort,
  }) {
    final query = select(playlistItems).join([
      innerJoin(mediaItems, mediaItems.id.equalsExp(playlistItems.mediaItemId)),
    ])..where(playlistItems.playlistId.equals(playlistId));

    if (sort != null) {
      query.orderBy([sort.orderingTerm(mediaItems)]);
    } else {
      query.orderBy([OrderingTerm.asc(playlistItems.sortOrder)]);
    }

    return query.map((row) => row.readTable(mediaItems)).get();
  }

  /// 監聽播放清單內的所有媒體項目（支援動態排序）
  Stream<List<MediaItem>> watchPlaylistMediaItems(
    String playlistId, {
    MediaSortOption? sort,
  }) {
    final query = select(playlistItems).join([
      innerJoin(mediaItems, mediaItems.id.equalsExp(playlistItems.mediaItemId)),
    ])..where(playlistItems.playlistId.equals(playlistId));

    if (sort != null) {
      query.orderBy([sort.orderingTerm(mediaItems)]);
    } else {
      query.orderBy([OrderingTerm.asc(playlistItems.sortOrder)]);
    }

    return query.map((row) => row.readTable(mediaItems)).watch();
  }

  /// 取得播放清單內的項目數量
  Future<int> getPlaylistItemCount(String playlistId) async {
    final count = countAll();
    final query = selectOnly(playlistItems)
      ..addColumns([count])
      ..where(playlistItems.playlistId.equals(playlistId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// 新增播放清單
  Future<void> insertPlaylist(PlaylistsCompanion playlist) {
    return into(playlists).insert(playlist);
  }

  /// 更新播放清單名稱
  Future<void> updatePlaylistName(String id, String newName) {
    return (update(playlists)..where((t) => t.id.equals(id))).write(
      PlaylistsCompanion(
        name: Value(newName),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 刪除播放清單（系統清單不可刪除）
  Future<int> deletePlaylist(String id) async {
    final playlist = await findById(id);
    if (playlist == null) return 0;
    if (playlist.type == 'system') return 0;

    // 先刪除關聯項目
    await (delete(playlistItems)..where((t) => t.playlistId.equals(id))).go();
    // 再刪除播放清單本身
    return (delete(playlists)..where((t) => t.id.equals(id))).go();
  }

  /// 新增曲目到播放清單
  Future<void> addItemToPlaylist(PlaylistItemsCompanion item) {
    return into(playlistItems).insert(item);
  }

  /// 從播放清單移除曲目
  Future<int> removeItemFromPlaylist(String playlistId, String mediaItemId) {
    return (delete(playlistItems)..where(
          (t) =>
              t.playlistId.equals(playlistId) &
              t.mediaItemId.equals(mediaItemId),
        ))
        .go();
  }

  /// 更新曲目排序
  Future<void> updateSortOrder(String playlistItemId, int newOrder) {
    return (update(playlistItems)..where((t) => t.id.equals(playlistItemId)))
        .write(PlaylistItemsCompanion(sortOrder: Value(newOrder)));
  }

  /// 檢查媒體項目是否已在播放清單中
  Future<bool> isItemInPlaylist(String playlistId, String mediaItemId) async {
    final result =
        await (select(playlistItems)..where(
              (t) =>
                  t.playlistId.equals(playlistId) &
                  t.mediaItemId.equals(mediaItemId),
            ))
            .getSingleOrNull();
    return result != null;
  }
}

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:muon/core/constants/app_constants.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  const uuid = Uuid();

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// 建立測試用 MediaItem（Playlist 測試需要先有媒體項目）
  Future<String> insertTestMediaItem({
    String? id,
    String sourceId = 'yt-test',
    String title = '測試歌曲',
  }) async {
    final itemId = id ?? uuid.v4();
    await db.mediaDao.insertMediaItem(
      MediaItemsCompanion.insert(
        id: itemId,
        sourceId: sourceId,
        title: title,
        channel: '測試頻道',
        durationMs: 180000,
        filePath: '/test/$sourceId.m4a',
        thumbnailPath: '/test/$sourceId.jpg',
      ),
    );
    return itemId;
  }

  group('PlaylistDao — 系統播放清單', () {
    test('資料庫初始化後自動建立 2 個系統播放清單', () async {
      final playlists = await db.playlistDao.getAllPlaylists();
      expect(playlists, hasLength(2));

      final ids = playlists.map((p) => p.id).toSet();
      expect(ids, contains(AppConstants.recentDownloadsPlaylistId));
      expect(ids, contains(AppConstants.favoritesPlaylistId));
    });

    test('系統播放清單類型為 system', () async {
      final playlist = await db.playlistDao.findById(
        AppConstants.favoritesPlaylistId,
      );
      expect(playlist, isNotNull);
      expect(playlist!.type, 'system');
    });

    test('系統播放清單不可刪除', () async {
      final deleted = await db.playlistDao.deletePlaylist(
        AppConstants.favoritesPlaylistId,
      );
      expect(deleted, 0);

      // 確認仍然存在
      final playlist = await db.playlistDao.findById(
        AppConstants.favoritesPlaylistId,
      );
      expect(playlist, isNotNull);
    });
  });

  group('PlaylistDao — 使用者播放清單 CRUD', () {
    test('建立使用者播放清單', () async {
      final id = uuid.v4();
      await db.playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(id: id, name: '我的清單'),
      );

      final playlist = await db.playlistDao.findById(id);
      expect(playlist, isNotNull);
      expect(playlist!.name, '我的清單');
      expect(playlist.type, 'user');
    });

    test('更新播放清單名稱', () async {
      final id = uuid.v4();
      await db.playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(id: id, name: '舊名稱'),
      );

      await db.playlistDao.updatePlaylistName(id, '新名稱');

      final playlist = await db.playlistDao.findById(id);
      expect(playlist!.name, '新名稱');
    });

    test('刪除使用者播放清單（含關聯項目清除）', () async {
      final playlistId = uuid.v4();
      await db.playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(id: playlistId, name: '要刪的清單'),
      );

      // 加入一首歌到清單
      final mediaId = await insertTestMediaItem();
      await db.playlistDao.addItemToPlaylist(
        PlaylistItemsCompanion.insert(
          id: uuid.v4(),
          playlistId: playlistId,
          mediaItemId: mediaId,
        ),
      );

      // 刪除
      final deleted = await db.playlistDao.deletePlaylist(playlistId);
      expect(deleted, 1);

      // 確認清單與關聯都已刪除
      final playlist = await db.playlistDao.findById(playlistId);
      expect(playlist, isNull);
    });
  });

  group('PlaylistDao — 曲目管理', () {
    test('新增曲目到播放清單', () async {
      final playlistId = uuid.v4();
      await db.playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(id: playlistId, name: '音樂清單'),
      );

      final mediaId = await insertTestMediaItem();
      await db.playlistDao.addItemToPlaylist(
        PlaylistItemsCompanion.insert(
          id: uuid.v4(),
          playlistId: playlistId,
          mediaItemId: mediaId,
        ),
      );

      final items = await db.playlistDao.getPlaylistMediaItems(playlistId);
      expect(items, hasLength(1));
      expect(items.first.id, mediaId);
    });

    test('從播放清單移除曲目', () async {
      final playlistId = uuid.v4();
      await db.playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(id: playlistId, name: '清單'),
      );

      final mediaId = await insertTestMediaItem();
      await db.playlistDao.addItemToPlaylist(
        PlaylistItemsCompanion.insert(
          id: uuid.v4(),
          playlistId: playlistId,
          mediaItemId: mediaId,
        ),
      );

      await db.playlistDao.removeItemFromPlaylist(playlistId, mediaId);

      final items = await db.playlistDao.getPlaylistMediaItems(playlistId);
      expect(items, isEmpty);
    });

    test('檢查曲目是否已在播放清單中', () async {
      final playlistId = uuid.v4();
      await db.playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(id: playlistId, name: '清單'),
      );

      final mediaId = await insertTestMediaItem();

      // 未加入前
      var exists = await db.playlistDao.isItemInPlaylist(playlistId, mediaId);
      expect(exists, isFalse);

      // 加入後
      await db.playlistDao.addItemToPlaylist(
        PlaylistItemsCompanion.insert(
          id: uuid.v4(),
          playlistId: playlistId,
          mediaItemId: mediaId,
        ),
      );

      exists = await db.playlistDao.isItemInPlaylist(playlistId, mediaId);
      expect(exists, isTrue);
    });

    test('取得播放清單項目數量', () async {
      final playlistId = uuid.v4();
      await db.playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(id: playlistId, name: '清單'),
      );

      final m1 = await insertTestMediaItem(sourceId: 's1');
      final m2 = await insertTestMediaItem(sourceId: 's2');

      await db.playlistDao.addItemToPlaylist(
        PlaylistItemsCompanion.insert(
          id: uuid.v4(),
          playlistId: playlistId,
          mediaItemId: m1,
        ),
      );
      await db.playlistDao.addItemToPlaylist(
        PlaylistItemsCompanion.insert(
          id: uuid.v4(),
          playlistId: playlistId,
          mediaItemId: m2,
        ),
      );

      final count = await db.playlistDao.getPlaylistItemCount(playlistId);
      expect(count, 2);
    });

    test('曲目排序', () async {
      final playlistId = uuid.v4();
      await db.playlistDao.insertPlaylist(
        PlaylistsCompanion.insert(id: playlistId, name: '排序清單'),
      );

      final m1 = await insertTestMediaItem(sourceId: 'sort1', title: '歌 A');
      final m2 = await insertTestMediaItem(sourceId: 'sort2', title: '歌 B');

      final itemId1 = uuid.v4();
      final itemId2 = uuid.v4();

      await db.playlistDao.addItemToPlaylist(
        PlaylistItemsCompanion.insert(
          id: itemId1,
          playlistId: playlistId,
          mediaItemId: m1,
          sortOrder: const Value(0),
        ),
      );
      await db.playlistDao.addItemToPlaylist(
        PlaylistItemsCompanion.insert(
          id: itemId2,
          playlistId: playlistId,
          mediaItemId: m2,
          sortOrder: const Value(1),
        ),
      );

      // 交換順序
      await db.playlistDao.updateSortOrder(itemId1, 1);
      await db.playlistDao.updateSortOrder(itemId2, 0);

      final items = await db.playlistDao.getPlaylistMediaItems(playlistId);
      expect(items, hasLength(2));
      expect(items[0].title, '歌 B');
      expect(items[1].title, '歌 A');
    });
  });
}

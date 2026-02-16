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

  group('MediaDao', () {
    /// 建立測試用 MediaItem companion
    MediaItemsCompanion createTestItem({
      String? id,
      String sourceId = 'yt-test-001',
      String title = '測試歌曲',
      String channel = '測試頻道',
      int durationMs = 180000,
      bool favorite = false,
    }) {
      return MediaItemsCompanion.insert(
        id: id ?? uuid.v4(),
        sourceId: sourceId,
        title: title,
        channel: channel,
        durationMs: durationMs,
        filePath: '/test/path/${sourceId}.m4a',
        thumbnailPath: '/test/path/${sourceId}.jpg',
        fileSize: Value(5000000),
        isVideo: const Value(false),
        favorite: Value(favorite),
      );
    }

    test('新增與查詢媒體項目', () async {
      final item = createTestItem(id: 'item-1');
      await db.mediaDao.insertMediaItem(item);

      final result = await db.mediaDao.findById('item-1');
      expect(result, isNotNull);
      expect(result!.title, '測試歌曲');
      expect(result.channel, '測試頻道');
      expect(result.durationMs, 180000);
    });

    test('取得所有媒體項目', () async {
      await db.mediaDao.insertMediaItem(createTestItem(title: '歌曲 A'));
      await db.mediaDao.insertMediaItem(createTestItem(
        sourceId: 'yt-test-002',
        title: '歌曲 B',
      ));

      final items = await db.mediaDao.getAllMediaItems();
      expect(items, hasLength(2));
    });

    test('依 sourceId 查詢（檢查已下載）', () async {
      await db.mediaDao.insertMediaItem(
        createTestItem(sourceId: 'yt-unique-id'),
      );

      final found = await db.mediaDao.findBySourceId('yt-unique-id');
      expect(found, isNotNull);
      expect(found!.sourceId, 'yt-unique-id');

      final notFound = await db.mediaDao.findBySourceId('non-existent');
      expect(notFound, isNull);
    });

    test('切換我的最愛', () async {
      final id = uuid.v4();
      await db.mediaDao.insertMediaItem(
        createTestItem(id: id, favorite: false),
      );

      // 加入最愛
      await db.mediaDao.toggleFavorite(id, true);
      var item = await db.mediaDao.findById(id);
      expect(item!.favorite, isTrue);

      // 移除最愛
      await db.mediaDao.toggleFavorite(id, false);
      item = await db.mediaDao.findById(id);
      expect(item!.favorite, isFalse);
    });

    test('取得我的最愛列表', () async {
      await db.mediaDao.insertMediaItem(
        createTestItem(sourceId: 'fav-1', title: '最愛 1', favorite: true),
      );
      await db.mediaDao.insertMediaItem(
        createTestItem(sourceId: 'fav-2', title: '最愛 2', favorite: true),
      );
      await db.mediaDao.insertMediaItem(
        createTestItem(sourceId: 'not-fav', title: '普通歌曲'),
      );

      final favorites = await db.mediaDao.getFavorites();
      expect(favorites, hasLength(2));
      expect(favorites.every((item) => item.favorite), isTrue);
    });

    test('更新播放記錄', () async {
      final id = uuid.v4();
      await db.mediaDao.insertMediaItem(createTestItem(id: id));

      // 播放一次
      await db.mediaDao.updatePlayRecord(id);
      var item = await db.mediaDao.findById(id);
      expect(item!.playCount, 1);
      expect(item.lastPlayedAt, isNotNull);

      // 再播放一次
      await db.mediaDao.updatePlayRecord(id);
      item = await db.mediaDao.findById(id);
      expect(item!.playCount, 2);
    });

    test('刪除媒體項目', () async {
      final id = uuid.v4();
      await db.mediaDao.insertMediaItem(createTestItem(id: id));

      final deleted = await db.mediaDao.deleteMediaItem(id);
      expect(deleted, 1);

      final result = await db.mediaDao.findById(id);
      expect(result, isNull);
    });

    test('本地搜尋（依標題或頻道）', () async {
      await db.mediaDao.insertMediaItem(
        createTestItem(sourceId: 's1', title: 'Flutter 教學', channel: '技術頻道'),
      );
      await db.mediaDao.insertMediaItem(
        createTestItem(sourceId: 's2', title: 'Dart 入門', channel: 'Flutter 頻道'),
      );
      await db.mediaDao.insertMediaItem(
        createTestItem(sourceId: 's3', title: '音樂 MV', channel: '流行音樂'),
      );

      // 搜尋標題
      final byTitle = await db.mediaDao.search('Flutter');
      expect(byTitle, hasLength(2)); // 標題或頻道含 Flutter

      // 搜尋頻道
      final byChannel = await db.mediaDao.search('流行');
      expect(byChannel, hasLength(1));
      expect(byChannel.first.title, '音樂 MV');

      // 無結果
      final noResult = await db.mediaDao.search('不存在');
      expect(noResult, isEmpty);
    });

    test('取得最近播放列表', () async {
      final id1 = uuid.v4();
      final id2 = uuid.v4();
      await db.mediaDao.insertMediaItem(
        createTestItem(id: id1, sourceId: 'r1', title: '歌 1'),
      );
      await db.mediaDao.insertMediaItem(
        createTestItem(id: id2, sourceId: 'r2', title: '歌 2'),
      );

      // 只有 id1 有播放記錄
      await db.mediaDao.updatePlayRecord(id1);

      final recent = await db.mediaDao.getRecentlyPlayed();
      expect(recent, hasLength(1));
      expect(recent.first.id, id1);
    });

    test('監聽媒體列表變化', () async {
      final stream = db.mediaDao.watchAllMediaItems();

      // 初始為空
      expect(await stream.first, isEmpty);

      // 新增後應自動收到更新
      await db.mediaDao.insertMediaItem(createTestItem());

      // 等待 Stream 更新
      final updated = await stream.first;
      expect(updated, hasLength(1));
    });
  });
}

---
name: flutter-drift-db
description: 使用 drift 操作 SQLite 資料庫。當需要建立或修改資料表、DAO、查詢或 migration 時觸發。
---

# Flutter Drift 資料庫操作

## 何時使用

- 建立或修改資料表（Table）
- 撰寫資料庫查詢（DAO）
- 建立 schema migration
- 處理多表關聯查詢

## 檔案結構

```
lib/data/database/
├── app_database.dart          # 主資料庫類別（@DriftDatabase）
├── tables/
│   ├── media_items.dart       # MediaItem 表定義
│   ├── playlists.dart         # Playlist 表定義
│   ├── playlist_items.dart    # PlaylistItem 關聯表
│   └── download_tasks.dart    # DownloadTask 表定義
└── daos/
    ├── media_dao.dart         # 媒體 CRUD
    ├── playlist_dao.dart      # 播放清單 CRUD
    └── download_dao.dart      # 下載任務 CRUD
```

## 範例模式

### 資料表定義

```dart
import 'package:drift/drift.dart';

/// 媒體項目資料表
class MediaItems extends Table {
  // 使用 UUID 作為主鍵
  TextColumn get id => text()();
  TextColumn get sourceId => text()(); // YouTube video ID
  TextColumn get title => text()();
  TextColumn get channel => text()();
  IntColumn get durationMs => integer()();
  TextColumn get filePath => text()();
  TextColumn get thumbnailPath => text()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  BoolColumn get isVideo => boolean().withDefault(const Constant(false))();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### DAO 定義

```dart
import 'package:drift/drift.dart';

part 'media_dao.g.dart';

@DriftAccessor(tables: [MediaItems])
class MediaDao extends DatabaseAccessor<AppDatabase> with _$MediaDaoMixin {
  MediaDao(AppDatabase db) : super(db);

  /// 取得所有媒體項目
  Future<List<MediaItem>> getAllMediaItems() => select(mediaItems).get();

  /// 依 sourceId 查詢（檢查是否已下載）
  Future<MediaItem?> findBySourceId(String sourceId) {
    return (select(mediaItems)
          ..where((t) => t.sourceId.equals(sourceId)))
        .getSingleOrNull();
  }

  /// 取得我的最愛
  Future<List<MediaItem>> getFavorites() {
    return (select(mediaItems)
          ..where((t) => t.favorite.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)]))
        .get();
  }

  /// 監聽媒體列表變化（回傳 Stream）
  Stream<List<MediaItem>> watchAllMediaItems() {
    return (select(mediaItems)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
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

  /// 更新播放記錄
  Future<void> updatePlayRecord(String id) {
    return (update(mediaItems)..where((t) => t.id.equals(id)))
        .write(MediaItemsCompanion(
      lastPlayedAt: Value(DateTime.now()),
      playCount: mediaItems.playCount + const Constant(1),
    ));
  }

  /// 刪除媒體項目
  Future<void> deleteMediaItem(String id) {
    return (delete(mediaItems)..where((t) => t.id.equals(id))).go();
  }
}
```

### 資料庫主類別

```dart
import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [MediaItems, Playlists, PlaylistItems, DownloadTasks],
  daos: [MediaDao, PlaylistDao, DownloadDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // 建立系統預設播放清單
        await _createSystemPlaylists();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 版本升級 migration
      },
    );
  }
}
```

## 重要提醒

- 修改表結構後執行 `dart run build_runner build --delete-conflicting-outputs`
- 使用 `Stream`（`.watch()`）搭配 Riverpod 的 `StreamProvider` 實現即時 UI 更新
- 外鍵關聯使用 `references()` 方法定義
- 複雜查詢建議使用 drift 的 SQL 模式（`customSelect`）
- Schema 變更時必須增加 `schemaVersion` 並在 `onUpgrade` 處理 migration

import 'package:drift/drift.dart';
import 'package:muon/core/constants/app_constants.dart';
import 'tables/media_items.dart';
import 'tables/playlists.dart';
import 'tables/playlist_items.dart';
import 'tables/download_tasks.dart';
import 'daos/media_dao.dart';
import 'daos/playlist_dao.dart';
import 'daos/download_dao.dart';

part 'app_database.g.dart';

/// Muon 主資料庫
///
/// 包含所有資料表與 DAO，支援 in-memory 模式（測試用）。
@DriftDatabase(
  tables: [MediaItems, Playlists, PlaylistItems, DownloadTasks],
  daos: [MediaDao, PlaylistDao, DownloadDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

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
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        // 移除廢棄的全部歌曲清單
        await (delete(
          playlists,
        )..where((t) => t.id.equals('system-all-songs'))).go();

        // 移除廢棄的最近下載清單
        await (delete(playlistItems)..where(
              (t) =>
                  t.playlistId.equals(AppConstants.recentDownloadsPlaylistId),
            ))
            .go();
        await (delete(playlists)..where(
              (t) => t.id.equals(AppConstants.recentDownloadsPlaylistId),
            ))
            .go();
      },
    );
  }

  /// 建立系統預設播放清單
  Future<void> _createSystemPlaylists() async {
    final now = DateTime.now();
    final systemPlaylists = [
      PlaylistsCompanion.insert(
        id: AppConstants.favoritesPlaylistId,
        name: '我的最愛',
        type: const Value('system'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    ];

    for (final playlist in systemPlaylists) {
      await into(playlists).insert(playlist);
    }
  }
}

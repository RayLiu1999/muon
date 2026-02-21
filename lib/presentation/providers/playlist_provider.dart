import 'package:drift/drift.dart' as drift;
import 'package:muon/core/constants/app_constants.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/presentation/providers/audio_provider.dart';
import 'package:muon/presentation/providers/database_provider.dart';
import 'package:muon/presentation/providers/media_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:audio_service/audio_service.dart' as audio;

part 'playlist_provider.g.dart';

/// 所有播放清單 (不含清單內項目)
@Riverpod(keepAlive: true)
Stream<List<Playlist>> allPlaylists(AllPlaylistsRef ref) {
  final db = ref.watch(databaseProvider);
  return db.playlistDao.watchAllPlaylists().map(
    (lists) => lists
        .where(
          (p) =>
              p.id != 'system-all-songs' &&
              p.id != AppConstants.recentDownloadsPlaylistId,
        )
        .toList(),
  );
}

/// 某個播放清單內的所有項目
@riverpod
Stream<List<MediaItem>> playlistMediaItems(
  PlaylistMediaItemsRef ref,
  String playlistId,
) {
  final db = ref.watch(databaseProvider);
  final sort = ref.watch(mediaSortOptionNotifierProvider);

  if (playlistId == AppConstants.favoritesPlaylistId) {
    return db.mediaDao.watchFavorites();
  }
  return db.playlistDao.watchPlaylistMediaItems(playlistId, sort: sort);
}

/// 播放清單管理邏輯
@riverpod
class PlaylistNotifier extends _$PlaylistNotifier {
  @override
  void build() {}

  /// 建立新的播放清單
  Future<void> createPlaylist(String name) async {
    final db = ref.read(databaseProvider);
    final id = const Uuid().v4();
    await db.playlistDao.insertPlaylist(
      PlaylistsCompanion.insert(
        id: id,
        name: name,
        type: const drift.Value('user'),
      ),
    );
  }

  /// 刪除播放清單
  Future<void> deletePlaylist(String id) async {
    final db = ref.read(databaseProvider);
    await db.playlistDao.deletePlaylist(id);
  }

  /// 更改清單名稱
  Future<void> updatePlaylistName(String id, String newName) async {
    final db = ref.read(databaseProvider);
    await db.playlistDao.updatePlaylistName(id, newName);
  }

  /// 新增媒體項目至此清單
  Future<void> addMediaToPlaylist(String playlistId, String mediaItemId) async {
    final db = ref.read(databaseProvider);
    final isExist = await db.playlistDao.isItemInPlaylist(
      playlistId,
      mediaItemId,
    );
    if (!isExist) {
      final count = await db.playlistDao.getPlaylistItemCount(playlistId);
      await db.playlistDao.addItemToPlaylist(
        PlaylistItemsCompanion.insert(
          id: const Uuid().v4(),
          playlistId: playlistId,
          mediaItemId: mediaItemId,
          sortOrder: drift.Value(count),
        ),
      );

      // 同步 AudioHandler 佇列
      final handler = ref.read(audioHandlerProvider);
      if (handler.currentCollectionId == playlistId) {
        final mediaItem = await db.mediaDao.findById(mediaItemId);
        if (mediaItem != null) {
          await handler.addQueueItem(_toAudioMediaItem(mediaItem));
        }
      }
    }
  }

  /// 從清單中移除媒體項目
  Future<void> removeMediaFromPlaylist(
    String playlistId,
    String mediaItemId,
  ) async {
    final db = ref.read(databaseProvider);
    await db.playlistDao.removeItemFromPlaylist(playlistId, mediaItemId);

    // 同步 AudioHandler 佇列
    final handler = ref.read(audioHandlerProvider);
    if (handler.currentCollectionId == playlistId) {
      final mediaItem = await db.mediaDao.findById(mediaItemId);
      if (mediaItem != null) {
        await handler.removeQueueItem(_toAudioMediaItem(mediaItem));
      }
    }
  }

  audio.MediaItem _toAudioMediaItem(MediaItem e) {
    Uri? artUri;
    if (e.thumbnailPath.isNotEmpty) {
      artUri = e.thumbnailPath.startsWith('http')
          ? Uri.tryParse(e.thumbnailPath)
          : Uri.file(e.thumbnailPath);
    }
    return audio.MediaItem(
      id: e.id,
      title: e.title,
      artist: e.channel,
      duration: Duration(milliseconds: e.durationMs),
      artUri: artUri,
      extras: {'filePath': e.filePath},
    );
  }
}

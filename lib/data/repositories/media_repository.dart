import 'dart:io';
import 'package:muon/core/utils/path_utils.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/data/database/daos/media_dao.dart';

extension _MediaItemMappers on MediaItem {
  MediaItem withResolvedPaths() {
    return copyWith(
      filePath: PathUtils.resolveSandboxPath(filePath),
      thumbnailPath:
          thumbnailPath.isNotEmpty && !thumbnailPath.startsWith('http')
          ? PathUtils.resolveSandboxPath(thumbnailPath)
          : thumbnailPath,
    );
  }
}

extension _MediaItemListMappers on List<MediaItem> {
  List<MediaItem> withResolvedPaths() =>
      map((e) => e.withResolvedPaths()).toList();
}

/// 媒體項目 Repository
///
/// 封裝 MediaDao，提供業務邏輯層使用。
/// 支援自動解析替換因 iOS UUID 變動失效的本機沙盒路徑。
class MediaRepository {
  final MediaDao _dao;

  MediaRepository(this._dao);

  /// 取得所有媒體項目
  Future<List<MediaItem>> getAllMediaItems({MediaSortOption? sort}) async =>
      (await _dao.getAllMediaItems(
        sort: sort ?? MediaSortOption.dateDesc,
      )).withResolvedPaths();

  /// 監聽所有媒體項目
  Stream<List<MediaItem>> watchAllMediaItems({MediaSortOption? sort}) => _dao
      .watchAllMediaItems(sort: sort ?? MediaSortOption.dateDesc)
      .map((items) => items.withResolvedPaths());

  /// 依 ID 查詢
  Future<MediaItem?> findById(String id) async {
    final item = await _dao.findById(id);
    return item?.withResolvedPaths();
  }

  /// 依 sourceId 查詢
  Future<MediaItem?> findBySourceId(String sourceId) async {
    final item = await _dao.findBySourceId(sourceId);
    return item?.withResolvedPaths();
  }

  /// 取得我的最愛
  Future<List<MediaItem>> getFavorites() async =>
      (await _dao.getFavorites()).withResolvedPaths();

  /// 監聯我的最愛
  Stream<List<MediaItem>> watchFavorites() =>
      _dao.watchFavorites().map((items) => items.withResolvedPaths());

  /// 取得最近播放
  Future<List<MediaItem>> getRecentlyPlayed({int limit = 20}) async =>
      (await _dao.getRecentlyPlayed(limit: limit)).withResolvedPaths();

  /// 取得最近下載
  Future<List<MediaItem>> getRecentlyDownloaded({int limit = 20}) async =>
      (await _dao.getRecentlyDownloaded(limit: limit)).withResolvedPaths();

  /// 切換最愛
  Future<void> toggleFavorite(String id, bool isFavorite) =>
      _dao.toggleFavorite(id, isFavorite);

  /// 更新播放記錄
  Future<void> updatePlayRecord(String id) => _dao.updatePlayRecord(id);

  /// 刪除（包含本機實體檔案）
  Future<int> deleteMediaItem(String id) async {
    final rawItem = await _dao.findById(id);
    if (rawItem != null) {
      final item = rawItem.withResolvedPaths();
      try {
        if (item.filePath.isNotEmpty) {
          final file = File(item.filePath);
          if (file.existsSync()) {
            file.deleteSync();
          }
          // 同步刪除可能存在的附加影片軌
          final videoPath = item.filePath.replaceAll('.m4a', '.mp4');
          final videoFile = File(videoPath);
          if (videoFile.existsSync()) {
            videoFile.deleteSync();
          }
        }
        if (item.thumbnailPath.isNotEmpty &&
            !item.thumbnailPath.startsWith('http')) {
          final thumbFile = File(item.thumbnailPath);
          if (thumbFile.existsSync()) {
            thumbFile.deleteSync();
          }
        }
      } catch (e) {
        // 忽略實體檔案刪除失敗的問題，繼續刪除資料庫紀錄
      }
    }
    return _dao.deleteMediaItem(id);
  }

  /// 搜尋
  Future<List<MediaItem>> search(String query) async =>
      (await _dao.search(query)).withResolvedPaths();

  /// 掃描並移除實體檔案不存在的媒體記錄（適用 macOS 外部刪除場景）
  ///
  /// 回傳被清除的筆數。
  Future<int> cleanupMissingFiles() async {
    final allRaw = await _dao.getAllMediaItems();
    int count = 0;
    for (final raw in allRaw) {
      final item = raw.withResolvedPaths();
      if (item.filePath.isNotEmpty && !File(item.filePath).existsSync()) {
        await deleteMediaItem(item.id);
        count++;
      }
    }
    return count;
  }
}

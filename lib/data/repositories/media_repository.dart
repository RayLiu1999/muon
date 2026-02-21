import 'dart:io';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/data/database/daos/media_dao.dart';

/// 媒體項目 Repository
///
/// 封裝 MediaDao，提供業務邏輯層使用。
/// 未來可在此加入快取策略或跨資料源整合。
class MediaRepository {
  final MediaDao _dao;

  MediaRepository(this._dao);

  /// 取得所有媒體項目
  Future<List<MediaItem>> getAllMediaItems() => _dao.getAllMediaItems();

  /// 監聽所有媒體項目
  Stream<List<MediaItem>> watchAllMediaItems() => _dao.watchAllMediaItems();

  /// 依 ID 查詢
  Future<MediaItem?> findById(String id) => _dao.findById(id);

  /// 依 sourceId 查詢
  Future<MediaItem?> findBySourceId(String sourceId) =>
      _dao.findBySourceId(sourceId);

  /// 取得我的最愛
  Future<List<MediaItem>> getFavorites() => _dao.getFavorites();

  /// 監聯我的最愛
  Stream<List<MediaItem>> watchFavorites() => _dao.watchFavorites();

  /// 取得最近播放
  Future<List<MediaItem>> getRecentlyPlayed({int limit = 20}) =>
      _dao.getRecentlyPlayed(limit: limit);

  /// 取得最近下載
  Future<List<MediaItem>> getRecentlyDownloaded({int limit = 20}) =>
      _dao.getRecentlyDownloaded(limit: limit);

  /// 切換最愛
  Future<void> toggleFavorite(String id, bool isFavorite) =>
      _dao.toggleFavorite(id, isFavorite);

  /// 更新播放記錄
  Future<void> updatePlayRecord(String id) => _dao.updatePlayRecord(id);

  /// 刪除（包含本機實體檔案）
  Future<int> deleteMediaItem(String id) async {
    final item = await _dao.findById(id);
    if (item != null) {
      try {
        if (item.filePath.isNotEmpty) {
          final file = File(item.filePath);
          if (file.existsSync()) {
            file.deleteSync();
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
  Future<List<MediaItem>> search(String query) => _dao.search(query);
}

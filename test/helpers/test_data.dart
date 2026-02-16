import 'package:uuid/uuid.dart';

/// 測試用假資料工廠
class TestData {
  TestData._();

  static const _uuid = Uuid();

  /// 建立測試用 MediaItem 資料（對應 drift companion）
  static Map<String, dynamic> createMediaItemMap({
    String? id,
    String sourceId = 'test-video-id',
    String title = '測試歌曲',
    String channel = '測試頻道',
    int durationMs = 180000,
    String filePath = '/test/path/song.m4a',
    String thumbnailPath = '/test/path/thumb.jpg',
    int fileSize = 5000000,
    bool isVideo = false,
    bool favorite = false,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    int playCount = 0,
  }) {
    return {
      'id': id ?? _uuid.v4(),
      'sourceId': sourceId,
      'title': title,
      'channel': channel,
      'durationMs': durationMs,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'fileSize': fileSize,
      'isVideo': isVideo,
      'favorite': favorite,
      'createdAt': createdAt ?? DateTime.now(),
      'lastPlayedAt': lastPlayedAt,
      'playCount': playCount,
    };
  }

  /// 建立測試用 Playlist 資料
  static Map<String, dynamic> createPlaylistMap({
    String? id,
    String name = '測試播放清單',
    String type = 'user',
    String? coverPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      'id': id ?? _uuid.v4(),
      'name': name,
      'type': type,
      'coverPath': coverPath,
      'createdAt': createdAt ?? now,
      'updatedAt': updatedAt ?? now,
    };
  }

  /// 建立測試用 DownloadTask 資料
  static Map<String, dynamic> createDownloadTaskMap({
    String? id,
    String sourceId = 'test-video-id',
    String title = '測試下載',
    String? thumbnailUrl,
    String status = 'queued',
    double progress = 0.0,
    String? filePath,
    String format = 'audio',
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return {
      'id': id ?? _uuid.v4(),
      'sourceId': sourceId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'status': status,
      'progress': progress,
      'filePath': filePath,
      'format': format,
      'errorMessage': errorMessage,
      'createdAt': createdAt ?? DateTime.now(),
    };
  }
}

/// Muon App 全域常數
class AppConstants {
  AppConstants._();

  /// App 名稱
  static const String appName = 'Muon';

  /// App 版本
  static const String appVersion = '0.2.2';

  /// 系統播放清單 ID（固定，不可刪除）
  static const String recentDownloadsPlaylistId = 'system-recent-downloads';
  static const String favoritesPlaylistId = 'system-favorites';

  /// 播放清單類型
  static const String playlistTypeSystem = 'system';
  static const String playlistTypeUser = 'user';

  /// 下載任務狀態
  static const String downloadStatusQueued = 'queued';
  static const String downloadStatusDownloading = 'downloading';
  static const String downloadStatusPaused = 'paused';
  static const String downloadStatusCompleted = 'completed';
  static const String downloadStatusFailed = 'failed';

  /// SharedPreferences keys
  static const String prefAutoResume = 'auto_resume';
  static const String prefBackendApiUrl = 'backend_api_url';
  static const String prefLastPlaylistId = 'last_playlist_id';
  static const String prefLastMediaItemId = 'last_media_item_id';
  static const String prefLastPosition = 'last_position';
}

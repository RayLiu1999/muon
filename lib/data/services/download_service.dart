import 'dart:async';
import 'package:drift/drift.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:uuid/uuid.dart';

/// 下載服務介面
///
/// 定義下載行為的抽象介面。
/// 真實實作會呼叫後端 API 並用 dio 下載。
/// Mock 實作模擬下載進度。
abstract class DownloadService {
  /// 開始下載
  ///
  /// [sourceId] YouTube 影片 ID
  /// [title] 影片標題
  /// [thumbnailUrl] 縮圖 URL
  /// [onProgress] 進度回呼（0.0 ~ 1.0）
  /// 回傳下載完成後的本機檔案路徑
  Future<String> download({
    required String sourceId,
    required String title,
    required String channel,
    required String duration,
    String? thumbnailUrl,
    String quality = 'best',
    String format = 'm4a',
    void Function(double progress)? onProgress,
  });
}

/// Mock 下載服務
///
/// 模擬下載行為，不需後端 API。
class MockDownloadService implements DownloadService {
  final AppDatabase _db;
  static const _uuid = Uuid();

  MockDownloadService(this._db);

  @override
  Future<String> download({
    required String sourceId,
    required String title,
    required String channel,
    required String duration,
    String? thumbnailUrl,
    String quality = 'best',
    String format = 'm4a',
    void Function(double progress)? onProgress,
  }) async {
    final taskId = _uuid.v4();
    final mediaId = _uuid.v4();

    // 建立下載任務記錄
    await _db.downloadDao.insertTask(
      DownloadTasksCompanion.insert(
        id: taskId,
        sourceId: sourceId,
        title: title,
        thumbnailUrl: Value(thumbnailUrl),
        status: const Value('downloading'),
      ),
    );

    // 模擬下載進度
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      final progress = i / 10.0;
      onProgress?.call(progress);
      await _db.downloadDao.updateProgress(taskId, progress);
    }

    // 模擬完成
    final filePath = '/mock/downloads/$sourceId.m4a';

    // 標記完成
    await _db.downloadDao.markCompleted(taskId, filePath);

    // 建立 MediaItem
    await _db.mediaDao.insertMediaItem(
      MediaItemsCompanion.insert(
        id: mediaId,
        sourceId: sourceId,
        title: title,
        channel: '已下載',
        durationMs: 180000,
        filePath: filePath,
        thumbnailPath: thumbnailUrl ?? '',
        fileSize: const Value(5000000),
      ),
    );

    return filePath;
  }
}

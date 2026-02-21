import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/data/services/download_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// 真實下載服務
///
/// 與 FastAPI 後端溝通，發起下載任務並輪詢進度，完成後下載檔案至本機。
class RealDownloadService implements DownloadService {
  final Dio _dio;
  final String baseUrl;
  final int pollingIntervalMs;
  final AppDatabase? _db; // 可選的 DB，方便純單元測試
  final Future<String> Function()? getSaveDir;

  RealDownloadService(
    this._dio, {
    required this.baseUrl,
    this.pollingIntervalMs = 1000,
    AppDatabase? db,
    this.getSaveDir,
  }) : _db = db;

  @override
  Future<String> download({
    required String sourceId,
    required String title,
    String? thumbnailUrl,
    void Function(double progress)? onProgress,
  }) async {
    // 1. 發起下載任務
    final response = await _dio.post(
      '$baseUrl/api/download',
      data: {
        'source_id': sourceId,
        'title': title,
        'thumbnail_url': thumbnailUrl ?? '',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('發起下載失敗');
    }

    final taskId = response.data['task_id'] as String;

    // 將任務狀態寫入 DB
    if (_db != null) {
      await _db.downloadDao.insertTask(
        DownloadTasksCompanion.insert(
          id: taskId,
          sourceId: sourceId,
          title: title,
          thumbnailUrl: Value(thumbnailUrl),
          status: const Value('downloading'),
        ),
      );
    }

    // 2. 輪詢進度
    bool isCompleted = false;
    while (!isCompleted) {
      await Future.delayed(Duration(milliseconds: pollingIntervalMs));

      try {
        final statusRes = await _dio.get(
          '$baseUrl/api/download/$taskId/status',
        );
        if (statusRes.statusCode == 200) {
          final statusData = statusRes.data;
          final status = statusData['status'] as String;
          final currentProgress =
              (statusData['progress'] as num?)?.toDouble() ?? 0.0;

          onProgress?.call(currentProgress);
          if (_db != null) {
            await _db.downloadDao.updateProgress(taskId, currentProgress);
          }

          if (status == 'completed') {
            isCompleted = true;
          } else if (status == 'failed') {
            if (_db != null) {
              await _db.downloadDao.updateStatus(taskId, 'failed');
            }
            throw Exception('後端下載失敗');
          }
        }
      } catch (e) {
        if (e is Exception && e.toString() == 'Exception: 後端下載失敗') {
          rethrow;
        }
        // 忽略網路瞬斷造成的查詢失敗，繼續輪詢
        print('輪詢狀態發生錯誤: $e');
      }
    }

    // 3. 從後端下載實體檔案到手機
    final String baseDir;
    if (getSaveDir != null) {
      baseDir = await getSaveDir!();
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      baseDir = appDir.path;
    }

    final fileExt = '.m4a'; // 目前固定為 m4a
    final savePath = '$baseDir/$sourceId$fileExt';

    await _dio.download(
      '$baseUrl/api/file/$taskId',
      savePath,
      onReceiveProgress: (received, total) {
        // 在此可以額外處理下載實體檔案的進度
      },
    );

    // 4. 下載完成，標記 DB
    if (_db != null) {
      await _db.downloadDao.markCompleted(taskId, savePath);

      // 建立 MediaItem
      final mediaId = 'media_$taskId';
      await _db.mediaDao.insertMediaItem(
        MediaItemsCompanion.insert(
          id: mediaId,
          sourceId: sourceId,
          title: title,
          channel: 'Downloaded',
          durationMs: 0, // 後端這版 API 尚未提供時長，後續可改良
          filePath: savePath,
          thumbnailPath: thumbnailUrl ?? '',
          fileSize: Value(File(savePath).lengthSync()),
        ),
      );
    }

    return savePath;
  }
}

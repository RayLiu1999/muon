// RealDownloadService
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:muon/core/utils/duration_formatter.dart';
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

  /// 追蹤各 sourceId 對應的 Dio CancelToken（用於取消實體檔案下載）
  final Map<String, CancelToken> _cancelTokens = {};

  /// 被標記為取消的 sourceId（用於中斷輪詢迴圈）
  final Set<String> _cancelledIds = {};

  RealDownloadService(
    this._dio, {
    required this.baseUrl,
    this.pollingIntervalMs = 1000,
    AppDatabase? db,
    this.getSaveDir,
  }) : _db = db;

  @override
  void cancelDownload(String sourceId) {
    // 標記為已取消，讓輪詢迴圈偵測到後跳出
    _cancelledIds.add(sourceId);

    // 取消正在進行的實體檔案下載
    final token = _cancelTokens[sourceId];
    if (token != null && !token.isCancelled) {
      token.cancel('使用者取消下載');
    }
    _cancelTokens.remove(sourceId);
  }

  @override
  Future<String> download({
    required String sourceId,
    required String title,
    required String channel,
    required String duration,
    String? thumbnailUrl,
    String quality = 'best',
    String format = 'm4a',
    Function(double)? onProgress,
  }) async {
    // 清除之前可能殘留的取消標記
    _cancelledIds.remove(sourceId);

    // 建立此次下載的 CancelToken
    final cancelToken = CancelToken();
    _cancelTokens[sourceId] = cancelToken;

    try {
      // 1. 發送下載請求給後端
      final response = await _dio.post(
        '$baseUrl/api/download',
        data: {
          'source_id': sourceId,
          'title': title,
          'thumbnail_url': thumbnailUrl ?? '',
          'quality': quality,
          'format': format,
        },
        cancelToken: cancelToken,
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

      // 2. 輪詢進度（偵測到取消時中斷）
      bool isCompleted = false;
      while (!isCompleted) {
        // 檢查是否被取消
        if (_cancelledIds.contains(sourceId)) {
          if (_db != null) {
            await _db.downloadDao.updateStatus(taskId, 'cancelled');
          }
          throw Exception('下載已取消');
        }

        await Future.delayed(Duration(milliseconds: pollingIntervalMs));

        try {
          final statusRes = await _dio.get(
            '$baseUrl/api/download/$taskId/status',
            cancelToken: cancelToken,
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
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) rethrow;
          // 忽略網路瞬斷造成的查詢失敗，繼續輪詢
          print('輪詢狀態發生錯誤: $e');
        } catch (e) {
          if (e is Exception && e.toString() == 'Exception: 後端下載失敗') {
            rethrow;
          }
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

      final fileExt = '.$format';
      final savePath = '$baseDir/$sourceId$fileExt';

      await _dio.download(
        '$baseUrl/api/file/$taskId',
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          // 在此可以額外處理下載實體檔案的進度
        },
      );

      // 4. 下載完成，標記 DB
      if (_db != null) {
        await _db.downloadDao.markCompleted(taskId, savePath);

        // 5. 將下載完成的資訊寫入資料庫
        await _db.mediaDao.insertMediaItem(
          MediaItemsCompanion.insert(
            id: sourceId,
            sourceId: sourceId,
            title: title,
            channel: channel,
            thumbnailPath: thumbnailUrl ?? '',
            filePath: savePath,
            durationMs: DurationFormatter.parse(duration).inMilliseconds,
            fileSize: Value(File(savePath).lengthSync()),
          ),
        );
      }

      return savePath;
    } finally {
      // 清理 CancelToken 與取消標記
      _cancelTokens.remove(sourceId);
      _cancelledIds.remove(sourceId);
    }
  }
}

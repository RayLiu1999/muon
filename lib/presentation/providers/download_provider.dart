import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/data/services/download_service.dart';
import 'package:muon/data/services/real_download_service.dart';
import 'package:muon/presentation/providers/database_provider.dart';
import 'package:muon/presentation/providers/dio_provider.dart';
import 'package:muon/presentation/providers/settings_provider.dart';

part 'download_provider.g.dart';

/// 下載服務 Provider
@Riverpod(keepAlive: true)
DownloadService downloadService(DownloadServiceRef ref) {
  final db = ref.watch(databaseProvider);
  final dio = ref.watch(dioProvider);
  final baseUrl = ref.watch(backendBaseUrlProvider);

  return RealDownloadService(dio, baseUrl: baseUrl, db: db);
}

/// 下載任務列表 Provider（串流）
@riverpod
Stream<List<DownloadTask>> downloadTasks(DownloadTasksRef ref) {
  final db = ref.watch(databaseProvider);
  return db.downloadDao.watchAllTasks();
}

/// 下載控制 Notifier
@riverpod
class DownloadNotifier extends _$DownloadNotifier {
  @override
  Map<String, double> build() {
    // 追蹤各 sourceId 的下載進度
    return {};
  }

  /// 開始下載
  Future<void> startDownload({
    required String sourceId,
    required String title,
    required String channel,
    required String duration,
    String? thumbnailUrl,
  }) async {
    // 檢查是否已經在下載中
    if (isDownloading(sourceId)) return;

    // 檢查資料庫是否已存在此檔案 (已下載過)
    final db = ref.read(databaseProvider);
    final existingMedia = await db.mediaDao.findBySourceId(sourceId);
    if (existingMedia != null) return;

    // 標記進度為 0
    state = {...state, sourceId: 0.0};

    try {
      final quality = ref.read(audioQualityProvider);
      final format = ref.read(downloadFormatProvider);
      final service = ref.read(downloadServiceProvider);
      await service.download(
        sourceId: sourceId,
        title: title,
        channel: channel,
        duration: duration,
        thumbnailUrl: thumbnailUrl,
        quality: quality,
        format: format,
        onProgress: (progress) {
          state = {...state, sourceId: progress};
        },
      );

      // 完成後移除進度追蹤
      final updatedState = Map<String, double>.from(state);
      updatedState.remove(sourceId);
      state = updatedState;

      // 強制重新載入媒體庫
      ref.invalidateSelf();
    } catch (e) {
      // 失敗時更新為 -1 表示錯誤
      state = {...state, sourceId: -1.0};
    }
  }

  /// 檢查是否正在下載
  bool isDownloading(String sourceId) {
    final progress = state[sourceId];
    return progress != null && progress >= 0;
  }

  /// 取得下載進度
  double? getProgress(String sourceId) {
    return state[sourceId];
  }
}

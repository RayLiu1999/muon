import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/download_tasks.dart';

part 'download_dao.g.dart';

/// 下載任務 DAO — 處理 DownloadTasks 的 CRUD 操作
@DriftAccessor(tables: [DownloadTasks])
class DownloadDao extends DatabaseAccessor<AppDatabase>
    with _$DownloadDaoMixin {
  DownloadDao(AppDatabase db) : super(db);

  /// 取得所有下載任務
  Future<List<DownloadTask>> getAllTasks() {
    return (select(downloadTasks)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 取得進行中的任務（queued + downloading）
  Future<List<DownloadTask>> getActiveTasks() {
    return (select(downloadTasks)
          ..where(
            (t) =>
                t.status.equals('queued') | t.status.equals('downloading'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// 取得已完成的任務
  Future<List<DownloadTask>> getCompletedTasks() {
    return (select(downloadTasks)
          ..where((t) => t.status.equals('completed'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 取得失敗的任務
  Future<List<DownloadTask>> getFailedTasks() {
    return (select(downloadTasks)
          ..where((t) => t.status.equals('failed'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 監聽所有任務變化
  Stream<List<DownloadTask>> watchAllTasks() {
    return (select(downloadTasks)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// 依 ID 查詢
  Future<DownloadTask?> findById(String id) {
    return (select(downloadTasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 依 sourceId 查詢（檢查是否已有下載任務）
  Future<DownloadTask?> findBySourceId(String sourceId) {
    return (select(downloadTasks)
          ..where((t) => t.sourceId.equals(sourceId)))
        .getSingleOrNull();
  }

  /// 新增下載任務
  Future<void> insertTask(DownloadTasksCompanion task) {
    return into(downloadTasks).insert(task);
  }

  /// 更新下載進度
  Future<void> updateProgress(String id, double progress) {
    return (update(downloadTasks)..where((t) => t.id.equals(id)))
        .write(DownloadTasksCompanion(progress: Value(progress)));
  }

  /// 更新任務狀態
  Future<void> updateStatus(String id, String status, {String? errorMessage}) {
    return (update(downloadTasks)..where((t) => t.id.equals(id))).write(
      DownloadTasksCompanion(
        status: Value(status),
        errorMessage: Value(errorMessage),
      ),
    );
  }

  /// 更新任務為完成（設定 filePath + status）
  Future<void> markCompleted(String id, String filePath) {
    return (update(downloadTasks)..where((t) => t.id.equals(id))).write(
      DownloadTasksCompanion(
        status: const Value('completed'),
        progress: const Value(1.0),
        filePath: Value(filePath),
      ),
    );
  }

  /// 刪除下載任務
  Future<int> deleteTask(String id) {
    return (delete(downloadTasks)..where((t) => t.id.equals(id))).go();
  }

  /// 刪除已完成的任務
  Future<int> deleteCompletedTasks() {
    return (delete(downloadTasks)
          ..where((t) => t.status.equals('completed')))
        .go();
  }
}

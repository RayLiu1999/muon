import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  const uuid = Uuid();

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// 建立測試用下載任務
  DownloadTasksCompanion createTestTask({
    String? id,
    String sourceId = 'yt-dl-001',
    String title = '測試下載',
    String status = 'queued',
    double progress = 0.0,
    String format = 'audio',
  }) {
    return DownloadTasksCompanion.insert(
      id: id ?? uuid.v4(),
      sourceId: sourceId,
      title: title,
      status: Value(status),
      progress: Value(progress),
      format: Value(format),
    );
  }

  group('DownloadDao — CRUD', () {
    test('新增並查詢下載任務', () async {
      final id = uuid.v4();
      await db.downloadDao.insertTask(createTestTask(id: id));

      final task = await db.downloadDao.findById(id);
      expect(task, isNotNull);
      expect(task!.title, '測試下載');
      expect(task.status, 'queued');
      expect(task.progress, 0.0);
    });

    test('取得所有任務', () async {
      await db.downloadDao.insertTask(createTestTask(sourceId: 'dl1'));
      await db.downloadDao.insertTask(createTestTask(sourceId: 'dl2'));

      final tasks = await db.downloadDao.getAllTasks();
      expect(tasks, hasLength(2));
    });

    test('依 sourceId 查詢', () async {
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'unique-source'),
      );

      final found = await db.downloadDao.findBySourceId('unique-source');
      expect(found, isNotNull);

      final notFound = await db.downloadDao.findBySourceId('non-existent');
      expect(notFound, isNull);
    });

    test('刪除任務', () async {
      final id = uuid.v4();
      await db.downloadDao.insertTask(createTestTask(id: id));

      final deleted = await db.downloadDao.deleteTask(id);
      expect(deleted, 1);

      final result = await db.downloadDao.findById(id);
      expect(result, isNull);
    });
  });

  group('DownloadDao — 狀態管理', () {
    test('更新任務狀態', () async {
      final id = uuid.v4();
      await db.downloadDao.insertTask(createTestTask(id: id));

      await db.downloadDao.updateStatus(id, 'downloading');
      var task = await db.downloadDao.findById(id);
      expect(task!.status, 'downloading');

      await db.downloadDao.updateStatus(
        id,
        'failed',
        errorMessage: '網路錯誤',
      );
      task = await db.downloadDao.findById(id);
      expect(task!.status, 'failed');
      expect(task.errorMessage, '網路錯誤');
    });

    test('更新下載進度', () async {
      final id = uuid.v4();
      await db.downloadDao.insertTask(createTestTask(id: id));

      await db.downloadDao.updateProgress(id, 0.5);
      var task = await db.downloadDao.findById(id);
      expect(task!.progress, closeTo(0.5, 0.001));

      await db.downloadDao.updateProgress(id, 0.9);
      task = await db.downloadDao.findById(id);
      expect(task!.progress, closeTo(0.9, 0.001));
    });

    test('標記任務完成', () async {
      final id = uuid.v4();
      await db.downloadDao.insertTask(createTestTask(id: id));

      await db.downloadDao.markCompleted(id, '/downloads/song.m4a');

      final task = await db.downloadDao.findById(id);
      expect(task!.status, 'completed');
      expect(task.progress, 1.0);
      expect(task.filePath, '/downloads/song.m4a');
    });
  });

  group('DownloadDao — 篩選查詢', () {
    test('取得進行中的任務', () async {
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'a1', status: 'queued'),
      );
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'a2', status: 'downloading'),
      );
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'a3', status: 'completed'),
      );
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'a4', status: 'failed'),
      );

      final active = await db.downloadDao.getActiveTasks();
      expect(active, hasLength(2));
      expect(
        active.every(
          (t) => t.status == 'queued' || t.status == 'downloading',
        ),
        isTrue,
      );
    });

    test('取得已完成的任務', () async {
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'c1', status: 'completed'),
      );
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'c2', status: 'queued'),
      );

      final completed = await db.downloadDao.getCompletedTasks();
      expect(completed, hasLength(1));
      expect(completed.first.status, 'completed');
    });

    test('取得失敗的任務', () async {
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'f1', status: 'failed'),
      );
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'f2', status: 'completed'),
      );

      final failed = await db.downloadDao.getFailedTasks();
      expect(failed, hasLength(1));
      expect(failed.first.status, 'failed');
    });

    test('刪除已完成的任務', () async {
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'dc1', status: 'completed'),
      );
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'dc2', status: 'completed'),
      );
      await db.downloadDao.insertTask(
        createTestTask(sourceId: 'dc3', status: 'queued'),
      );

      final deleted = await db.downloadDao.deleteCompletedTasks();
      expect(deleted, 2);

      final remaining = await db.downloadDao.getAllTasks();
      expect(remaining, hasLength(1));
      expect(remaining.first.status, 'queued');
    });
  });

  group('DownloadDao — Stream 監聽', () {
    test('監聽任務變化', () async {
      final stream = db.downloadDao.watchAllTasks();

      // 初始為空
      expect(await stream.first, isEmpty);

      // 新增後應收到更新
      await db.downloadDao.insertTask(createTestTask());
      final updated = await stream.first;
      expect(updated, hasLength(1));
    });
  });
}

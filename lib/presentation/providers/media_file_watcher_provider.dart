import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muon/presentation/providers/media_provider.dart';
import 'package:muon/presentation/providers/settings_provider.dart';

part 'media_file_watcher_provider.g.dart';

/// macOS 檔案系統監聽器
///
/// 監聽下載目錄（預設及使用者自訂），當外部程式刪除音訊檔案時，
/// 自動從資料庫中移除對應的媒體記錄，保持媒體庫與磁碟狀態同步。
/// 非 macOS 平台為 no-op。
@Riverpod(keepAlive: true)
class MediaFileWatcher extends _$MediaFileWatcher {
  final List<StreamSubscription<FileSystemEvent>> _subs = [];

  @override
  void build() {
    if (!Platform.isMacOS) return;

    // 當 provider 被銷毀時取消所有監聽
    ref.onDispose(_cancelAll);

    // 啟動對預設文件目錄的監聽
    _initWatchers();

    // 當使用者自訂下載目錄改變時，重新設定監聽
    ref.listen(downloadDirectoryProvider, (_, __) {
      _cancelAll();
      _initWatchers();
    });
  }

  Future<void> _initWatchers() async {
    // 1. 預設 documents 目錄
    final docsDir = await getApplicationDocumentsDirectory();
    _watchDirectory(docsDir.path);

    // 2. 使用者自訂目錄（若有設定且與預設不同）
    final customDir = ref.read(downloadDirectoryProvider);
    if (customDir.isNotEmpty && customDir != docsDir.path) {
      _watchDirectory(customDir);
    }
  }

  void _watchDirectory(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return;

    final sub = dir
        .watch(events: FileSystemEvent.delete | FileSystemEvent.move)
        .listen((event) async {
      final deletedPath = event.path;
      final repo = ref.read(mediaRepositoryProvider);
      final allItems = await repo.getAllMediaItems();
      for (final item in allItems) {
        if (item.filePath == deletedPath) {
          // 直接刪除 DB 記錄（實體檔案已不存在，略過刪除檔案步驟）
          await repo.deleteMediaItem(item.id);
          break;
        }
      }
    });

    _subs.add(sub);
  }

  void _cancelAll() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }
}

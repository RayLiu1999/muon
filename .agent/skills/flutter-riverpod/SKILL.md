---
name: flutter-riverpod
description: 使用 Riverpod code generation 模式建立狀態管理。當需要建立新的 Provider、StateNotifier 或非同步狀態時觸發。
---

# Flutter Riverpod（Code Generation 模式）

## 何時使用

- 新增功能需要狀態管理
- 建立新的 Provider
- 處理非同步資料（API 呼叫、資料庫查詢）

## 規則

1. **一律使用 code generation 模式**（`@riverpod` annotation），不使用手動 Provider 定義
2. **檔案命名**：Provider 檔案放在 `lib/presentation/providers/` 目錄下
3. **產生的檔案**：每個 `.dart` 檔案搭配 `.g.dart`，需在檔案頂部加入 `part` 指令

## 範例模式

### 簡單 Provider（唯讀、無狀態）

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'greeting_provider.g.dart';

/// 簡單的同步 Provider
@riverpod
String greeting(GreetingRef ref) {
  return '歡迎使用 OfflineYT Player';
}
```

### Async Provider（非同步資料）

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_list_provider.g.dart';

/// 從資料庫讀取媒體列表
@riverpod
Future<List<MediaItem>> mediaList(MediaListRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.mediaDao.getAllMediaItems();
}
```

### Notifier（可變狀態，有方法）

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_state_provider.g.dart';

/// 播放器狀態管理
@riverpod
class PlayerState extends _$PlayerState {
  @override
  PlayerStateModel build() {
    return const PlayerStateModel.initial();
  }

  void play(MediaItem item) {
    state = state.copyWith(currentItem: item, isPlaying: true);
  }

  void pause() {
    state = state.copyWith(isPlaying: false);
  }
}
```

### AsyncNotifier（非同步可變狀態）

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'download_queue_provider.g.dart';

/// 下載佇列管理
@riverpod
class DownloadQueue extends _$DownloadQueue {
  @override
  Future<List<DownloadTask>> build() async {
    final db = ref.watch(databaseProvider);
    return db.downloadDao.getActiveTasks();
  }

  Future<void> addTask(DownloadTask task) async {
    final db = ref.read(databaseProvider);
    await db.downloadDao.insertTask(task);
    ref.invalidateSelf();
  }
}
```

## 重要提醒

- 修改 Provider 後執行 `dart run build_runner build --delete-conflicting-outputs`
- `ref.watch` 用於 build 方法內（會自動重建）
- `ref.read` 用於事件處理器內（一次性讀取）
- `ref.listen` 用於監聽副作用（如 SnackBar 通知）
- `keepAlive` 模式：@Riverpod(keepAlive: true) 用於全域長期存活的 Provider

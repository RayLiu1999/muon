---
name: flutter-testing
description: 撰寫 Flutter 單元測試與 Widget 測試。當需要為新功能撰寫測試、驗證邏輯或測試 UI 元件時觸發。
---

# Flutter 測試

## 何時使用

- 新增功能後撰寫測試
- 修改邏輯後驗證正確性
- 測試 Widget 行為與 UI 互動

## 測試結構

```
test/
├── data/
│   ├── database/
│   │   └── daos/
│   │       ├── media_dao_test.dart
│   │       └── playlist_dao_test.dart
│   ├── repositories/
│   │   └── media_repository_test.dart
│   └── services/
│       └── download_service_test.dart
├── presentation/
│   ├── providers/
│   │   └── player_state_provider_test.dart
│   └── widgets/
│       └── mini_player_test.dart
└── audio/
    └── audio_handler_test.dart
```

## 範例模式

### 單元測試（Repository / Service）

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock 類別
class MockMediaDao extends Mock implements MediaDao {}

void main() {
  late MediaRepository repository;
  late MockMediaDao mockDao;

  setUp(() {
    mockDao = MockMediaDao();
    repository = MediaRepository(mockDao);
  });

  group('MediaRepository', () {
    test('取得所有媒體項目', () async {
      // Arrange（準備）
      final items = [createTestMediaItem()];
      when(() => mockDao.getAllMediaItems()).thenAnswer((_) async => items);

      // Act（執行）
      final result = await repository.getAllMediaItems();

      // Assert（驗證）
      expect(result, equals(items));
      verify(() => mockDao.getAllMediaItems()).called(1);
    });

    test('切換我的最愛', () async {
      when(() => mockDao.toggleFavorite(any(), any()))
          .thenAnswer((_) async {});

      await repository.toggleFavorite('test-id', true);

      verify(() => mockDao.toggleFavorite('test-id', true)).called(1);
    });
  });
}
```

### Riverpod Provider 測試

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('playerProvider 初始狀態為未播放', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(playerStateProvider);
    expect(state.isPlaying, isFalse);
    expect(state.currentItem, isNull);
  });
}
```

### Widget 測試

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('MiniPlayer 顯示目前曲目標題', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 覆寫 Provider 提供測試資料
          currentMediaItemProvider.overrideWithValue(
            createTestMediaItem(title: '測試歌曲'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MiniPlayer()),
        ),
      ),
    );

    expect(find.text('測試歌曲'), findsOneWidget);
  });
}
```

## 常用指令

```bash
# 執行全部測試
flutter test

# 執行特定測試檔案
flutter test test/data/repositories/media_repository_test.dart

# 測試覆蓋率
flutter test --coverage
```

## 重要提醒

- 使用 `mocktail` 套件做 mock（比 `mockito` 更簡潔，不需 code generation）
- Riverpod Provider 測試使用 `ProviderContainer`
- Widget 測試需用 `ProviderScope` 包裝
- 測試檔案命名：`{原始檔名}_test.dart`
- 每個 public 方法至少一個正向 + 一個異常測試

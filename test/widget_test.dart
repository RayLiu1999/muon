import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/presentation/pages/home/home_page.dart';
import 'package:muon/presentation/providers/database_provider.dart';

import 'helpers/test_database.dart';

void main() {
  testWidgets('HomePage 啟動並顯示媒體庫空狀態', (WidgetTester tester) async {
    final db = createTestDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    // 等待非同步載入
    await tester.pumpAndSettle();

    // 驗證空狀態提示
    expect(find.text('媒體庫'), findsOneWidget);
    expect(find.text('媒體庫是空的'), findsOneWidget);

    await db.close();
  });
}

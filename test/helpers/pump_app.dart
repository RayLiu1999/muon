import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/core/theme/app_theme.dart';

/// 測試用 Widget 包裝器
///
/// 提供 ProviderScope + MaterialApp，方便 Widget 測試使用。
Widget createTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

/// 測試用 Scaffold 包裝器
///
/// 當 Widget 需要 Scaffold 環境時使用。
Widget createTestScaffold({
  required Widget body,
  List<Override> overrides = const [],
}) {
  return createTestApp(
    overrides: overrides,
    child: Scaffold(body: body),
  );
}

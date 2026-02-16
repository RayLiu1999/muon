import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/app.dart';

/// Muon App 進入點
///
/// Phase 3 會在此加入 AudioService.init() 與資料庫初始化。
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MuonApp(),
    ),
  );
}

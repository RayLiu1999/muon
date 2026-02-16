import 'package:flutter/material.dart';
import 'package:muon/core/theme/app_theme.dart';
import 'package:muon/core/constants/app_constants.dart';

/// Muon App 根 Widget
class MuonApp extends StatelessWidget {
  const MuonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      // 暫時使用簡單首頁，Phase 4 會替換為 GoRouter
      home: const _PlaceholderHome(),
    );
  }
}

/// 暫時的首頁佔位（Phase 4 會替換為完整 GoRouter 導航）
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
      ),
      body: const Center(
        child: Text(
          'Muon v0.1',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

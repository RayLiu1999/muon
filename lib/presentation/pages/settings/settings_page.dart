import 'package:flutter/material.dart';

/// 設定頁佔位（Phase 7 實作）
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: const Center(
        child: Text('設定功能建置中...'),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// 搜尋頁佔位（Phase 5 實作）
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜尋'),
      ),
      body: const Center(
        child: Text('搜尋功能建置中...'),
      ),
    );
  }
}

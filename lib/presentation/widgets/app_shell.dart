import 'package:flutter/material.dart';

/// App 底部導航殼層
///
/// 提供 BottomNavigationBar（首頁 / 搜尋 / 設定）和 MiniPlayer 預留位置。
class AppShell extends StatelessWidget {
  /// 當前子頁面
  final Widget child;

  /// 當前選中的 tab 索引
  final int currentIndex;

  /// tab 切換回呼
  final ValueChanged<int> onTabSelected;

  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      // Phase 6 會在此加入 MiniPlayer
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: '媒體庫',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '搜尋',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

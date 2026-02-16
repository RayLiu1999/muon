import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muon/presentation/widgets/mini_player.dart';

/// App 底部導航殼層
///
/// 提供 BottomNavigationBar（首頁 / 搜尋 / 設定）和 MiniPlayer。
class AppShell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // MiniPlayer（有播放中曲目時自動顯示）
          const MiniPlayer(),
          // 底部導航列
          BottomNavigationBar(
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
        ],
      ),
    );
  }
}

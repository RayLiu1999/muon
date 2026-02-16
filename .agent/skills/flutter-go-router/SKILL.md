---
name: flutter-go-router
description: 使用 go_router 設定路由與導航。當需要新增頁面、設定導航結構、處理 ShellRoute 或 deep link 時觸發。
---

# Flutter go_router 路由設定

## 何時使用

- 新增頁面或路由
- 修改導航結構
- 設定底部導航列與 ShellRoute
- 處理 deep link 或重導向

## 本專案導航架構

```
GoRouter
├── ShellRoute（含 BottomNavigationBar + Mini Player）
│   ├── /home          → 首頁（媒體庫）
│   ├── /search        → YouTube 搜尋頁
│   └── /settings      → 設定頁
├── /search/downloads  → 下載佇列頁
├── /playlist/:id      → 播放清單詳情頁
├── /player            → 全螢幕播放器
└── /storage           → 儲存空間管理
```

## 核心設定範例

### Router 設定（app.dart）

```dart
import 'package:go_router/go_router.dart';

/// 全域路由 key（用於在 ShellRoute 外導航）
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    // ShellRoute：包含底部導航列 + Mini Player
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomePage(),
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SearchPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsPage(),
          ),
        ),
      ],
    ),
    // ShellRoute 外的頁面（全螢幕，不含底部導航列）
    GoRoute(
      path: '/player',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FullScreenPlayerPage(),
    ),
    GoRoute(
      path: '/search/downloads',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DownloadQueuePage(),
    ),
    GoRoute(
      path: '/playlist/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final playlistId = state.pathParameters['id']!;
        return PlaylistDetailPage(playlistId: playlistId);
      },
    ),
  ],
);
```

### AppShell（底部導航 + Mini Player）

```dart
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      // Mini Player 放在 bottomNavigationBar 上方
      bottomSheet: const MiniPlayer(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜尋'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home');
      case 1: context.go('/search');
      case 2: context.go('/settings');
    }
  }
}
```

## 重要提醒

- `context.go()` 用於底部導航列切換（替換頁面）
- `context.push()` 用於進入子頁面（堆疊頁面，有返回按鈕）
- ShellRoute 內使用 `NoTransitionPage` 避免 tab 切換的過場動畫
- 全螢幕播放器使用 `parentNavigatorKey: _rootNavigatorKey` 確保覆蓋整個畫面
- Mini Player 的點擊展開應使用 `context.push('/player')`

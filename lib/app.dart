import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:muon/core/constants/app_constants.dart';
import 'package:muon/core/theme/app_theme.dart';
import 'package:muon/presentation/pages/home/home_page.dart';
import 'package:muon/presentation/pages/search/search_page.dart';
import 'package:muon/presentation/pages/settings/settings_page.dart';
import 'package:muon/presentation/pages/home/playlist_detail_page.dart';
import 'package:muon/presentation/pages/player/full_screen_player_page.dart';
import 'package:muon/presentation/pages/player/video_player_page.dart';
import 'dart:io';
import 'package:muon/presentation/providers/settings_provider.dart';
import 'package:muon/presentation/providers/audio_provider.dart';
import 'package:muon/presentation/providers/media_file_watcher_provider.dart';
import 'package:muon/presentation/widgets/app_shell.dart';
import 'package:muon/presentation/widgets/macos_shell.dart';

/// 路由路徑常數
class AppRoutes {
  AppRoutes._();
  static const String home = '/';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String player = '/player';
}

// ── 過渡動畫輔助函式 ─────────────────────────────────────────────
/// 淡入淡出（macOS 子頁面標準風格）
Page<void> _fadePage(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity:
            CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      ),
    );

/// 從右側滑入（行動版 drill-down 標準風格）
Page<void> _slideRightPage(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

/// 從下方淡入滑出（播放器頁面 / modal 風格）
Page<void> _slideUpFadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.07),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity:
              CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        ),
      ),
    );
// ────────────────────────────────────────────────────────────────

/// GoRouter 設定
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    // ShellRoute — 提供殼層（macOS 用側邊欄版，手機用底部導航列版）
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        void onTabSelected(int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        }

        if (Platform.isMacOS) {
          return MacOSShell(
            currentIndex: navigationShell.currentIndex,
            onTabSelected: onTabSelected,
            child: navigationShell,
          );
        }

        return AppShell(
          currentIndex: navigationShell.currentIndex,
          onTabSelected: onTabSelected,
          child: navigationShell,
        );
      },
      branches: [
        // 首頁分支
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomePage()),
              routes: [
                // 播放清單內容頁
                GoRoute(
                  path: 'playlist/:id',
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final title = state.extra as String? ?? '播放清單';
                    final child =
                        PlaylistDetailPage(playlistId: id, title: title);
                    // macOS：淡入；行動版：從右側滑入
                    return Platform.isMacOS
                        ? _fadePage(state, child)
                        : _slideRightPage(state, child);
                  },
                ),
                // 音訊播放頁（在殼層內顯示，側邊欄/底部列保持可見）
                GoRoute(
                  path: 'player',
                  pageBuilder: (context, state) => _slideUpFadePage(
                      state, const FullScreenPlayerPage()),
                  routes: [
                    // 影片播放頁
                    GoRoute(
                      path: 'video',
                      pageBuilder: (context, state) {
                        final extra =
                            state.extra as Map<String, String>;
                        final child = VideoPlayerPage(
                          videoPath: extra['videoPath']!,
                          title: extra['title'] ?? '',
                        );
                        return Platform.isMacOS
                            ? _fadePage(state, child)
                            : _slideRightPage(state, child);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // 搜尋分支
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.search,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SearchPage()),
            ),
          ],
        ),
        // 設定分支
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsPage()),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Muon App 根 Widget
class MuonApp extends ConsumerWidget {
  const MuonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // macOS：啟動檔案系統監聽，自動同步外部刪除的音訊檔案
    if (Platform.isMacOS) ref.watch(mediaFileWatcherProvider);

    // 監聽當前播放曲目，持久化 ID 供下次啟動恢復用
    ref.listen(currentMediaItemProvider, (_, next) {
      next.whenData((item) {
        if (item != null) {
          ref
              .read(sharedPreferencesProvider)
              .setString('last_played_id', item.id);
        }
      });
    });

    // 讀取主題設定（字串：system, light, dark）
    final themeStr = ref.watch(themeModeNotifierProvider);
    ThemeMode themeMode;
    switch (themeStr) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
        break;
    }

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}

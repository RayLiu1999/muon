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
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final title = state.extra as String? ?? '播放清單';
                    return PlaylistDetailPage(playlistId: id, title: title);
                  },
                ),
                // 音訊播放頁（在殼層內顯示，側邊欄/底部列保持可見）
                GoRoute(
                  path: 'player',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: FullScreenPlayerPage()),
                  routes: [
                    // 影片播放頁（在殼層內顯示；全螢幕透過 windowManager 控制）
                    GoRoute(
                      path: 'video',
                      builder: (context, state) {
                        final extra =
                            state.extra as Map<String, String>;
                        return VideoPlayerPage(
                          videoPath: extra['videoPath']!,
                          title: extra['title'] ?? '',
                        );
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muon/core/constants/app_constants.dart';
import 'package:muon/core/theme/app_theme.dart';
import 'package:muon/presentation/pages/home/home_page.dart';
import 'package:muon/presentation/pages/search/search_page.dart';
import 'package:muon/presentation/pages/settings/settings_page.dart';
import 'package:muon/presentation/widgets/app_shell.dart';

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
    // ShellRoute — 提供 BottomNavigationBar 殼層
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          currentIndex: navigationShell.currentIndex,
          onTabSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          child: navigationShell,
        );
      },
      branches: [
        // 首頁分支
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomePage(),
              ),
            ),
          ],
        ),
        // 搜尋分支
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.search,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SearchPage(),
              ),
            ),
          ],
        ),
        // 設定分支
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsPage(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Muon App 根 Widget
class MuonApp extends StatelessWidget {
  const MuonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'package:muon/presentation/providers/playlist_provider.dart';
import 'package:muon/presentation/widgets/macos_player_bar.dart';

/// macOS 專屬殼層 — Spotify 風格三欄佈局
///
/// 結構：[Sidebar | 主內容] + 底部播放列
/// 僅在 Platform.isMacOS 時使用，手機版仍使用原本的 AppShell。
class MacOSShell extends ConsumerWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MacOSShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // ── 主體：Sidebar + 內容 ────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // 左側導航欄
                _MacOSSidebar(
                  currentIndex: currentIndex,
                  onTabSelected: onTabSelected,
                ),
                // 分隔線
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.dividerColor,
                ),
                // 主內容區
                Expanded(child: child),
              ],
            ),
          ),
          // ── 底部播放列 ──────────────────────────────────────────
          const MacOSPlayerBar(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Sidebar
// ──────────────────────────────────────────────────────────────────────────────

class _MacOSSidebar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _MacOSSidebar({
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const double _kSidebarWidth = 220;
  static const double _kTrafficLightsHeight = 28; // hiddenInset 留給按鈕的空間

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sidebarBg = theme.colorScheme.surface;

    return SizedBox(
      width: _kSidebarWidth,
      child: ColoredBox(
        color: sidebarBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── traffic lights 佔位 + 可拖曳區域 ───────────────────
            DragToMoveArea(
              child: SizedBox(
                height: _kTrafficLightsHeight,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 8),

            // ── 主要導航項目 ───────────────────────────────────────
            _NavItem(
              icon: Icons.library_music,
              label: '媒體庫',
              selected: currentIndex == 0,
              onTap: () => onTabSelected(0),
            ),
            _NavItem(
              icon: Icons.search,
              label: '搜尋',
              selected: currentIndex == 1,
              onTap: () => onTabSelected(1),
            ),
            _NavItem(
              icon: Icons.settings,
              label: '設定',
              selected: currentIndex == 2,
              onTap: () => onTabSelected(2),
            ),

            // ── 播放清單區塊 ───────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                '播放清單',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Expanded(
              child: _PlaylistsList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 單個導航項目 ──────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.75);
    final bgColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 播放清單列表 ──────────────────────────────────────────────────────────────

class _PlaylistsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(allPlaylistsProvider);
    final theme = Theme.of(context);

    return playlistsAsync.when(
      data: (playlists) => ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          final isSystem = playlist.type == 'system';
          return InkWell(
            onTap: () => context.go(
              '/playlist/${playlist.id}',
              extra: playlist.name,
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  Icon(
                    isSystem ? Icons.favorite : Icons.playlist_play,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

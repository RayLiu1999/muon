import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'package:muon/data/database/app_database.dart';
import 'package:muon/presentation/providers/playlist_provider.dart';
import 'package:muon/presentation/widgets/macos_player_bar.dart';

/// 新增播放清單對話框
Future<void> _showCreatePlaylistDialog(
    BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('新增播放清單'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '播放清單名稱'),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('建立'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (name != null && name.isNotEmpty) {
    await ref.read(playlistNotifierProvider.notifier).createPlaylist(name);
  }
}

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

  static const double _kSidebarWidth = 260;
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

            // ── 播放清單區塊標題 + 新增按鈕 ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '播放清單',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.add,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      tooltip: '新增播放清單',
                      onPressed: () => _showCreatePlaylistDialog(context, ref),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
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

class _NavItem extends StatefulWidget {
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
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.75);
    final bgColor = widget.selected
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : _isHovered
            ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: color),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 播放清單列表 ──────────────────────────────────────────────────────────────

class _PlaylistsList extends ConsumerWidget {
  const _PlaylistsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(allPlaylistsProvider);
    return playlistsAsync.when(
      data: (playlists) => ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: playlists.length,
        itemBuilder: (context, index) =>
            _PlaylistItem(playlist: playlists[index]),
      ),
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class _PlaylistItem extends ConsumerStatefulWidget {
  final Playlist playlist;

  const _PlaylistItem({required this.playlist});

  @override
  ConsumerState<_PlaylistItem> createState() => _PlaylistItemState();
}

class _PlaylistItemState extends ConsumerState<_PlaylistItem> {
  bool _isHovered = false;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除播放清單'),
        content: Text('確定要刪除「${widget.playlist.name}」？此動作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '刪除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(playlistNotifierProvider.notifier)
          .deletePlaylist(widget.playlist.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSystem = widget.playlist.type == 'system';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: _isHovered
              ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => context.go(
            '/playlist/${widget.playlist.id}',
            extra: widget.playlist.name,
          ),
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.transparent,
          child: Padding(
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
                    widget.playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (!isSystem)
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: GestureDetector(
                      onTap: () => _confirmDelete(context),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 15,
                          color: theme.colorScheme.error.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

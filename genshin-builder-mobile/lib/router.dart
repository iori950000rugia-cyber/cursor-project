import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/artifacts/artifact_sets_screen.dart';
import 'features/bootstrap/initial_sync_screen.dart';
import 'features/bookmarks/bookmarks_screen.dart';
import 'features/characters/character_detail_screen.dart';
import 'features/characters/character_list_screen.dart';
import 'features/daily_materials/daily_materials_screen.dart';
import 'features/gacha/gacha_screen.dart';
import 'features/hoyolab/hoyolab_settings_screen.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/bootstrap',
  routes: [
    GoRoute(
      path: '/bootstrap',
      builder: (context, state) => const InitialSyncScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/characters',
          builder: (context, state) => const CharacterListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => CharacterDetailScreen(
                characterId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/daily',
          builder: (context, state) => const DailyMaterialsScreen(),
        ),
        GoRoute(
          path: '/artifacts',
          builder: (context, state) => const ArtifactSetsScreen(),
        ),
        GoRoute(
          path: '/bookmarks',
          builder: (context, state) => const BookmarksScreen(),
        ),
        GoRoute(
          path: '/gacha',
          builder: (context, state) => const GachaScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'hoyolab',
              builder: (context, state) => const HoyolabSettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _NavItem {
  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _navItems = <_NavItem>[
  _NavItem(
    path: '/',
    label: 'ホーム',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  _NavItem(
    path: '/characters',
    label: 'キャラ',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  _NavItem(
    path: '/daily',
    label: '曜日',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today,
  ),
  _NavItem(
    path: '/artifacts',
    label: '聖遺物',
    icon: Icons.diamond_outlined,
    selectedIcon: Icons.diamond,
  ),
  _NavItem(
    path: '/bookmarks',
    label: '素材',
    icon: Icons.bookmark_outline,
    selectedIcon: Icons.bookmark,
  ),
  _NavItem(
    path: '/gacha',
    label: 'ガチャ',
    icon: Icons.casino_outlined,
    selectedIcon: Icons.casino,
  ),
  _NavItem(
    path: '/settings',
    label: '設定',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];

/// Shell の Scaffold にアクセスして endDrawer を開く。
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.scaffoldKey,
    required super.child,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  static AppShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellScope>();

  static void openEndDrawer(BuildContext context) {
    maybeOf(context)?.scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) =>
      scaffoldKey != oldWidget.scaffoldKey;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex(String path) {
    if (path.startsWith('/characters')) return 1;
    if (path.startsWith('/daily')) return 2;
    if (path.startsWith('/artifacts')) return 3;
    if (path.startsWith('/bookmarks')) return 4;
    if (path.startsWith('/gacha')) return 5;
    if (path.startsWith('/settings')) return 6;
    return 0;
  }

  void _go(BuildContext context, int index) {
    Navigator.of(context).maybePop();
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(path);
    final theme = Theme.of(context);

    return AppShellScope(
      scaffoldKey: _scaffoldKey,
      child: Scaffold(
        key: _scaffoldKey,
        body: widget.child,
        endDrawerEnableOpenDragGesture: true,
        endDrawer: NavigationDrawer(
          selectedIndex: selected,
          onDestinationSelected: (i) => _go(context, i),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 16, 8),
              child: Text('メニュー', style: theme.textTheme.titleSmall),
            ),
            for (final item in _navItems)
              NavigationDrawerDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              ),
          ],
        ),
      ),
    );
  }
}

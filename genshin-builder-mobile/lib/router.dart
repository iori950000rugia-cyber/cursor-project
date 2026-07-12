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
import 'navigation/android_system_back.dart';

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
  bool _endDrawerOpen = false;
  bool _handlingSystemBack = false;

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

  bool _isEndDrawerOpen() =>
      _endDrawerOpen ||
      (_scaffoldKey.currentState?.isEndDrawerOpen ?? false);

  Future<bool> _onAndroidBackButton() async {
    if (_handlingSystemBack || !mounted) return true;
    if (!isAndroidSystemBackHandlingEnabled) return false;

    if (_isEndDrawerOpen()) {
      _scaffoldKey.currentState?.closeEndDrawer();
      return true;
    }

    final path = GoRouterState.of(context).uri.path;

    // トップレベル上の Dialog / Sheet は Navigator に任せる
    if (!isShellNestedLocation(path) &&
        Navigator.of(context, rootNavigator: true).canPop()) {
      return false;
    }

    // ネスト詳細は GoRouter / Navigator の通常 pop
    if (isShellNestedLocation(path)) {
      return false;
    }

    if (isShellHomePath(path)) {
      return true;
    }

    _handlingSystemBack = true;
    try {
      context.go('/');
    } finally {
      _handlingSystemBack = false;
    }
    return true;
  }

  void _onSystemBackInvoked(bool didPop, Object? result) {
    // Predictive Back / PopScope 経路。didPop 時は二重処理しない。
    if (didPop || _handlingSystemBack || !mounted) return;
    if (!isAndroidSystemBackHandlingEnabled) return;

    final drawerOpen = _isEndDrawerOpen();
    if (androidSystemBackShouldCloseDrawer(
      didPop: didPop,
      isEndDrawerOpen: drawerOpen,
    )) {
      _scaffoldKey.currentState?.closeEndDrawer();
      return;
    }

    final path = GoRouterState.of(context).uri.path;
    if (!androidSystemBackShouldGoHome(
      locationPath: path,
      isEndDrawerOpen: drawerOpen,
    )) {
      return;
    }

    _handlingSystemBack = true;
    try {
      context.go('/');
    } finally {
      _handlingSystemBack = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(path);
    final theme = Theme.of(context);

    Widget body = widget.child;
    if (isAndroidSystemBackHandlingEnabled) {
      // BackButtonListener: GoRouter より先に Drawer / Home 消費を処理できる
      // PopScope: Predictive Back の canPop 提示用
      body = BackButtonListener(
        onBackButtonPressed: _onAndroidBackButton,
        child: Builder(
          builder: (bodyContext) {
            final drawerOpen = Scaffold.of(bodyContext).isEndDrawerOpen ||
                _endDrawerOpen;
            return PopScope(
              canPop: androidSystemBackCanPop(
                locationPath: path,
                isEndDrawerOpen: drawerOpen,
              ),
              onPopInvokedWithResult: _onSystemBackInvoked,
              child: widget.child,
            );
          },
        ),
      );
    }

    return AppShellScope(
      scaffoldKey: _scaffoldKey,
      child: Scaffold(
        key: _scaffoldKey,
        endDrawerEnableOpenDragGesture: true,
        onEndDrawerChanged: (isOpen) {
          if (_endDrawerOpen == isOpen) return;
          setState(() => _endDrawerOpen = isOpen);
        },
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
        body: body,
      ),
    );
  }
}

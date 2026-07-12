import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genshin_builder_mobile/navigation/android_system_back.dart';
import 'package:genshin_builder_mobile/router.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('android_system_back helpers', () {
    test('isShellHomePath', () {
      expect(isShellHomePath('/'), isTrue);
      expect(isShellHomePath(''), isTrue);
      expect(isShellHomePath('/characters'), isFalse);
    });

    test('isShellNestedLocation', () {
      expect(isShellNestedLocation('/characters/foo'), isTrue);
      expect(isShellNestedLocation('/settings/hoyolab'), isTrue);
      expect(isShellNestedLocation('/characters'), isFalse);
      expect(isShellNestedLocation('/settings'), isFalse);
      expect(isShellNestedLocation('/'), isFalse);
    });

    test('androidSystemBackCanPop', () {
      expect(
        androidSystemBackCanPop(
          locationPath: '/characters/a',
          isEndDrawerOpen: false,
        ),
        isTrue,
      );
      expect(
        androidSystemBackCanPop(
          locationPath: '/characters/a',
          isEndDrawerOpen: true,
        ),
        isFalse,
      );
      expect(
        androidSystemBackCanPop(
          locationPath: '/characters',
          isEndDrawerOpen: false,
        ),
        isFalse,
      );
    });

    test('androidSystemBackShouldGoHome', () {
      expect(
        androidSystemBackShouldGoHome(
          locationPath: '/characters',
          isEndDrawerOpen: false,
        ),
        isTrue,
      );
      expect(
        androidSystemBackShouldGoHome(
          locationPath: '/',
          isEndDrawerOpen: false,
        ),
        isFalse,
      );
      expect(
        androidSystemBackShouldGoHome(
          locationPath: '/characters/a',
          isEndDrawerOpen: false,
        ),
        isFalse,
      );
      expect(
        androidSystemBackShouldGoHome(
          locationPath: '/daily',
          isEndDrawerOpen: true,
        ),
        isFalse,
      );
    });

    test('isAndroidSystemBackHandlingEnabled respects platform override', () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(isAndroidSystemBackHandlingEnabled, isTrue);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(isAndroidSystemBackHandlingEnabled, isFalse);
    });
  });

  group('AppShell Android system back', () {
    late GoRouter router;
    late List<MethodCall> platformCalls;

    Future<void> runAndroidTest(
      WidgetTester tester,
      Future<void> Function() body,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      platformCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        platformCalls.add(call);
        return null;
      });
      router = _testShellRouter();
      try {
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        await body();
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
        router.dispose();
        debugDefaultTargetPlatformOverride = null;
      }
    }

    Future<void> systemBack(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    bool sawSystemNavigatorPop() => platformCalls.any(
          (c) => c.method == 'SystemNavigator.pop',
        );

    testWidgets('nested detail pops to parent without go home', (tester) async {
      await runAndroidTest(tester, () async {
        router.go('/characters/demo');
        await tester.pumpAndSettle();
        expect(find.text('detail:demo'), findsOneWidget);

        await systemBack(tester);

        expect(find.text('characters'), findsOneWidget);
        expect(find.text('home'), findsNothing);
        expect(router.state.uri.path, '/characters');
        expect(sawSystemNavigatorPop(), isFalse);
      });
    });

    testWidgets('nested pop does not skip two levels', (tester) async {
      await runAndroidTest(tester, () async {
        router.go('/settings/hoyolab');
        await tester.pumpAndSettle();
        expect(find.text('hoyolab'), findsOneWidget);

        await systemBack(tester);

        expect(router.state.uri.path, '/settings');
        expect(find.text('settings'), findsOneWidget);
        expect(find.text('home'), findsNothing);
      });
    });

    for (final path in const [
      '/characters',
      '/daily',
      '/artifacts',
      '/bookmarks',
      '/gacha',
      '/settings',
    ]) {
      testWidgets('toplevel $path goes home', (tester) async {
        await runAndroidTest(tester, () async {
          router.go(path);
          await tester.pumpAndSettle();

          await systemBack(tester);

          expect(router.state.uri.path, '/');
          expect(find.text('home'), findsOneWidget);
          expect(sawSystemNavigatorPop(), isFalse);
        });
      });
    }

    testWidgets('home consumes back and does not request exit', (tester) async {
      await runAndroidTest(tester, () async {
        expect(router.state.uri.path, '/');

        for (var i = 0; i < 10; i++) {
          await systemBack(tester);
          expect(router.state.uri.path, '/');
          expect(find.text('home'), findsOneWidget);
        }

        expect(sawSystemNavigatorPop(), isFalse);
        expect(find.text('home'), findsOneWidget);
      });
    });

    testWidgets('dialog closes without going home on same back', (tester) async {
      await runAndroidTest(tester, () async {
        router.go('/characters');
        await tester.pumpAndSettle();

        final shellContext = tester.element(find.byType(AppShell));
        showDialog<void>(
          context: shellContext,
          builder: (ctx) => const AlertDialog(
            title: Text('dlg'),
            content: Text('dialog-body'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('dialog-body'), findsOneWidget);

        await systemBack(tester);

        expect(find.text('dialog-body'), findsNothing);
        expect(router.state.uri.path, '/characters');
        expect(find.text('characters'), findsOneWidget);
        expect(find.text('home'), findsNothing);
      });
    });

    testWidgets('drawer closes without popping detail', (tester) async {
      await runAndroidTest(tester, () async {
        router.go('/characters/demo');
        await tester.pumpAndSettle();

        final scope = tester.widget<AppShellScope>(find.byType(AppShellScope));
        final scaffoldState = scope.scaffoldKey.currentState!;
        scaffoldState.openEndDrawer();
        await tester.pumpAndSettle();
        expect(scaffoldState.isEndDrawerOpen, isTrue);

        await systemBack(tester);

        expect(scaffoldState.isEndDrawerOpen, isFalse);
        expect(router.state.uri.path, '/characters/demo');
        expect(find.text('detail:demo'), findsOneWidget);
      });
    });

    testWidgets('didPop true path does not force go home', (tester) async {
      await runAndroidTest(tester, () async {
        router.go('/characters/demo');
        await tester.pumpAndSettle();

        await systemBack(tester);
        expect(router.state.uri.path, '/characters');
        expect(find.text('home'), findsNothing);
      });
    });
  });

  group('AppShell non-Android keeps default back', () {
    testWidgets('no PopScope on iOS shell', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final router = _testShellRouter();
      try {
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(find.byType(PopScope), findsNothing);
        expect(find.byType(BackButtonListener), findsNothing);
      } finally {
        router.dispose();
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('home back may request SystemNavigator.pop', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final platformCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        platformCalls.add(call);
        return null;
      });
      final router = _testShellRouter();
      try {
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(router.state.uri.path, '/');

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(
          platformCalls.any((c) => c.method == 'SystemNavigator.pop'),
          isTrue,
        );
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
        router.dispose();
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}

GoRouter _testShellRouter() {
  Widget page(String label) => Center(child: Text(label));

  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => page('home')),
          GoRoute(
            path: '/characters',
            builder: (_, __) => page('characters'),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    page('detail:${state.pathParameters['id']}'),
              ),
            ],
          ),
          GoRoute(path: '/daily', builder: (_, __) => page('daily')),
          GoRoute(path: '/artifacts', builder: (_, __) => page('artifacts')),
          GoRoute(path: '/bookmarks', builder: (_, __) => page('bookmarks')),
          GoRoute(path: '/gacha', builder: (_, __) => page('gacha')),
          GoRoute(
            path: '/settings',
            builder: (_, __) => page('settings'),
            routes: [
              GoRoute(
                path: 'hoyolab',
                builder: (_, __) => page('hoyolab'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

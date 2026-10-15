import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taleb/app/pages/auth_pages.dart';
import 'package:taleb/l10n/app_localizations.dart';

void main() {
  testWidgets('role picker starts with account creation like the reference', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: [Locale('en')],
        locale: Locale('en'),
        home: RoleSelectionPage(),
      ),
    );

    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Choose the account type that suits you'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Guardian'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(3));
    final artwork = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(artwork, hasLength(3));
    expect(
      (artwork[0].image as AssetImage).assetName,
      'assets/student_background.png',
    );
    expect(
      (artwork[1].image as AssetImage).assetName,
      'assets/teacher_background.png',
    );
    expect(
      (artwork[2].image as AssetImage).assetName,
      'assets/parents_background.png',
    );
  });

  testWidgets('selected role continues to its matching registration flow', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const RoleSelectionPage()),
        GoRoute(
          path: '/register',
          builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
      ),
    );

    final continueFinder = find.text('Continue');
    await tester.scrollUntilVisible(
      continueFinder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(continueFinder, findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.ensureVisible(find.text('Teacher'));
    await tester.tap(find.text('Teacher'));
    await tester.pump();
    await tester.scrollUntilVisible(
      continueFinder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text('/register?role=teacher'), findsOneWidget);
    expect(router.canPop(), isTrue);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionPage), findsOneWidget);
    router.dispose();
  });
}

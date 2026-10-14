import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/app/app.dart';
import 'package:taleb/app/pages/auth_pages.dart';
import 'package:taleb/l10n/app_localizations.dart';

void main() {
  testWidgets('missing Supabase configuration shows a diagnostic', (
    tester,
  ) async {
    await tester.pumpWidget(const ConfigMissingApp());
    expect(find.textContaining('Supabase is not configured'), findsOneWidget);
  });

  testWidgets('welcome page exposes sign in and account creation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: [Locale('ar'), Locale('en')],
        locale: Locale('ar'),
        home: WelcomePage(),
      ),
    );
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('إنشاء حساب'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
  });

  testWidgets('role selection presents all three account types', (
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
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Guardian'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/app/pages/auth_pages.dart';
import 'package:taleb/features/auth/domain/entities/account_role.dart';
import 'package:taleb/l10n/app_localizations.dart';

void main() {
  testWidgets('guardian home does not expose student data without a link', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: [Locale('en')],
        locale: Locale('en'),
        home: Scaffold(body: RoleHomeContent(role: AccountRole.guardian)),
      ),
    );

    expect(find.text('Guardian space'), findsOneWidget);
    expect(
      find.text(
        'Student information will appear only after an active relationship is accepted.',
      ),
      findsOneWidget,
    );
    expect(find.text('Attendance'), findsNothing);
    expect(find.text('Grades'), findsNothing);
  });

  testWidgets('each role gets its own localized home state', (tester) async {
    for (final (role, expected) in [
      (AccountRole.student, 'Student space'),
      (AccountRole.teacher, 'Teacher space'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Scaffold(body: RoleHomeContent(role: role)),
        ),
      );
      expect(find.text(expected), findsOneWidget);
    }
  });

  testWidgets('guardian state is localized and RTL in Arabic', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: [Locale('ar')],
        locale: Locale('ar'),
        home: Scaffold(body: RoleHomeContent(role: AccountRole.guardian)),
      ),
    );

    expect(find.text('مساحة ولي الأمر'), findsOneWidget);
    expect(
      find.text('لن تظهر معلومات الطالب إلا بعد قبول علاقة نشطة.'),
      findsOneWidget,
    );
    expect(
      Directionality.of(tester.element(find.byType(RoleHomeContent))),
      TextDirection.rtl,
    );
  });
}

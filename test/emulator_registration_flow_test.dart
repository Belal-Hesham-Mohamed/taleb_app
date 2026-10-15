import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/app/locale_cubit.dart';
import 'package:taleb/app/pages/student_registration_page.dart';
import 'package:taleb/core/storage/locale_repository.dart';
import 'package:taleb/features/auth/data/repositories/fake_registration_repository.dart';
import 'package:taleb/features/auth/domain/repositories/registration_repository.dart';
import 'package:taleb/l10n/app_localizations.dart';

class _InMemoryLocaleRepository implements LocaleRepository {
  String? _code;

  @override
  Future<String?> read() async => _code;

  @override
  Future<void> write(String code) async => _code = code;
}

Future<void> _pump(
  WidgetTester tester,
  FakeRegistrationRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: BlocProvider.value(
        value: LocaleCubit(_InMemoryLocaleRepository()),
        child: StudentRegistrationPage(repository: repository),
      ),
    ),
  );
}

Future<void> _enter(WidgetTester tester, Finder finder, String text) async {
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Next'));
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

/// Opens the [index]-th dropdown and picks [option].
Future<void> _pickDropdown(
  WidgetTester tester,
  int index,
  String option,
) async {
  final dropdown = find.byWidgetPredicate(
    (widget) => widget is DropdownButtonFormField,
  );
  final target = dropdown.at(index);
  await tester.ensureVisible(target);
  final arrow = find.descendant(
    of: target,
    matching: find.byIcon(Icons.arrow_drop_down),
  );
  await tester.tap(arrow, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  final item = find.text(option).last;
  await tester.ensureVisible(item);
  await tester.tap(item, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Fills the credentials step with [phone].
Future<void> _fillCredentials(WidgetTester tester, String phone) async {
  await _enter(tester, find.byType(TextFormField).at(0), phone);
  await _enter(tester, find.byType(TextFormField).at(1), 'secret123');
  await _enter(tester, find.byType(TextFormField).at(2), 'secret123');
  await _tapNext(tester);
}

/// Fills the personal step.
Future<void> _fillPersonal(WidgetTester tester) async {
  await _enter(tester, find.byType(TextFormField).at(0), 'Ahmed Mohamed');
  await tester.tap(find.text('Select date'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Male'));
  await tester.pumpAndSettle();
  await _enter(tester, find.byType(TextFormField).at(2), '01234567891');
  await _pickDropdown(tester, 0, 'Cairo');
  await _pickDropdown(tester, 1, 'Nasr City');
  await _tapNext(tester);
}

/// Fills the education step with a simple primary selection.
Future<void> _fillEducation(WidgetTester tester) async {
  await _pickDropdown(tester, 0, 'General');
  await _pickDropdown(tester, 1, 'Primary');
  await _pickDropdown(tester, 2, 'Grade 4 primary');
  await _tapNext(tester);
}

void main() {
  // Mirrors the emulator scenario: FAKE_REGISTRATION is enabled, one number
  // is already taken, everything else is free.
  FakeRegistrationRepository newRepository() =>
      FakeRegistrationRepository(takenNumbers: ['+201234567890']);

  testWidgets('the emulator scenario blocks a taken number on step 1', (
    tester,
  ) async {
    final repository = newRepository();
    await _pump(tester, repository);

    await _fillCredentials(tester, '01234567890');

    expect(
      find.text('This phone number is already registered. Use another number.'),
      findsOneWidget,
    );
    expect(find.text('Login data'), findsOneWidget);
    expect(repository.availabilityCalls, 1);
  });

  testWidgets('a free number advances and completes the whole flow', (
    tester,
  ) async {
    final repository = newRepository();
    await _pump(tester, repository);

    await _fillCredentials(tester, '01555555555');
    expect(find.text('Personal data'), findsOneWidget);
    await _fillPersonal(tester);
    expect(find.text('Academic data'), findsOneWidget);
    await _fillEducation(tester);
    expect(find.text('Review your data'), findsOneWidget);

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Your account has been created'), findsOneWidget);
    expect(repository.registrationCalls, 1);
    expect(repository.createdNumbers, ['+201555555555']);
  });

  testWidgets('a number registered in the same session is then taken', (
    tester,
  ) async {
    final repository = newRepository();
    await _pump(tester, repository);

    await _fillCredentials(tester, '01555555555');
    await _fillPersonal(tester);
    await _fillEducation(tester);
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Your account has been created'), findsOneWidget);

    // The fake records the created number, so a later availability check
    // reports it as taken — the same state a real backend would hold.
    final result = await repository.checkPhoneAvailability('+201555555555');
    expect(result.status, PhoneAvailabilityStatus.taken);
    expect(repository.createdNumbers, ['+201555555555']);
  });

  testWidgets('a failed availability check does not advance', (tester) async {
    final repository = newRepository()..failNextAvailabilityCheck = true;
    await _pump(tester, repository);

    await _fillCredentials(tester, '01555555555');

    expect(find.text('We could not check the number. Try again.'), findsOneWidget);
    expect(find.text('Login data'), findsOneWidget);
  });

  testWidgets('a failed creation keeps the user on review', (tester) async {
    final repository = newRepository()..failNextRegistration = true;
    await _pump(tester, repository);

    await _fillCredentials(tester, '01555555555');
    await _fillPersonal(tester);
    await _fillEducation(tester);
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Your account has been created'), findsNothing);
    expect(find.text('Review your data'), findsOneWidget);
    expect(repository.createdNumbers, isEmpty);
  });

  testWidgets('the flow is usable in Arabic on the emulator', (tester) async {
    final repository = newRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: BlocProvider.value(
          value: LocaleCubit(_InMemoryLocaleRepository()),
          child: StudentRegistrationPage(repository: repository),
        ),
      ),
    );
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
    await _enter(tester, find.byType(TextFormField).at(0), '01234567890');
    await _enter(tester, find.byType(TextFormField).at(1), 'secret123');
    await _enter(tester, find.byType(TextFormField).at(2), 'secret123');
    await tester.ensureVisible(find.text('التالي'));
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(
      find.text('رقم الهاتف مسجل بالفعل. استخدم رقماً آخر.'),
      findsOneWidget,
    );
  });
}

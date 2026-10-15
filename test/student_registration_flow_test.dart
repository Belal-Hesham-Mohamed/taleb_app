import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taleb/app/locale_cubit.dart';
import 'package:taleb/app/pages/auth_pages.dart';
import 'package:taleb/app/pages/student_registration_page.dart';
import 'package:taleb/core/errors/failure.dart';
import 'package:taleb/core/storage/locale_repository.dart';
import 'package:taleb/features/auth/domain/entities/catalog.dart';
import 'package:taleb/features/auth/domain/entities/account_role.dart';
import 'package:taleb/features/auth/domain/entities/user_profile.dart';
import 'package:taleb/features/auth/domain/repositories/auth_repository.dart';
import 'package:taleb/features/auth/domain/repositories/registration_repository.dart';
import 'package:taleb/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:taleb/l10n/app_localizations.dart';

/// A LocaleCubit backed by an in-memory repository so the registration page's
/// language toggle works without platform channels.
class _TestLocaleCubit extends LocaleCubit {
  _TestLocaleCubit() : super(_InMemoryLocaleRepository());
}

class _InMemoryLocaleRepository implements LocaleRepository {
  String? _code;

  @override
  Future<String?> read() async => _code;

  @override
  Future<void> write(String code) async => _code = code;
}

/// An AuthCubit that never performs I/O, for tests that only mount the
/// existing email-based registration page.
class _NoopAuthCubit extends AuthCubit {
  _NoopAuthCubit() : super(_NoopAuthRepository());
}

class _NoopAuthRepository implements AuthRepository {
  final controller = StreamController<AuthChange>.broadcast();

  @override
  Stream<AuthChange> get authChanges => controller.stream;

  @override
  Future<Either<Failure, UserProfile?>> restoreSession() async =>
      const Right(null);

  @override
  Future<Either<Failure, UserProfile>> signIn(
    String email,
    String password,
  ) async => const Left(Failure(FailureKind.invalidCredentials));

  @override
  Future<Either<Failure, UserProfile?>> signUp({
    required String email,
    required String password,
    required String fullName,
    required AccountRole role,
    String? school,
    String? grade,
  }) async => const Right(null);

  @override
  Future<Either<Failure, Unit>> signOut() async => const Right(unit);

  @override
  Future<Either<Failure, UserProfile>> currentProfile() async =>
      const Left(Failure(FailureKind.profileNotFound));

  @override
  Future<Either<Failure, Unit>> requestPasswordReset(String email) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> updatePassword(String password) async =>
      const Right(unit);
}

class _FakeRegistrationRepository
    implements RegistrationRepository, CatalogRepository {
  PhoneAvailability availabilityResult = const PhoneAvailability(
    status: PhoneAvailabilityStatus.available,
    phone: '+201234567890',
  );
  Completer<PhoneAvailability>? availabilityCompleter;
  int availabilityCalls = 0;
  List<String> checkedPhones = [];

  RegistrationFailure? registerResult;
  Completer<void>? registerCompleter;
  int registerCalls = 0;
  StudentRegistrationRequest? capturedRequest;

  @override
  Future<PhoneAvailability> checkPhoneAvailability(String phone) async {
    availabilityCalls++;
    checkedPhones.add(phone);
    return availabilityCompleter?.future ?? availabilityResult;
  }

  @override
  Future<void> registerStudent(StudentRegistrationRequest request) async {
    registerCalls++;
    capturedRequest = request;
    await registerCompleter?.future;
    if (registerResult != null) throw registerResult!;
  }

  @override
  Future<List<CatalogOption>> loadPrograms() async => [
    const CatalogOption(
      id: 1,
      code: 'general',
      nameAr: 'عام',
      nameEn: 'General',
    ),
  ];

  @override
  Future<List<CatalogOption>> loadStages() async => [
    const CatalogOption(
      id: 1,
      code: 'primary',
      nameAr: 'ابتدائي',
      nameEn: 'Primary',
    ),
    const CatalogOption(
      id: 3,
      code: 'secondary',
      nameAr: 'ثانوي',
      nameEn: 'Secondary',
    ),
  ];

  @override
  Future<List<GradeOption>> loadGrades({
    required int programId,
    required int stageId,
  }) async {
    if (stageId == 1) {
      return [
        const GradeOption(
          id: 104,
          nameAr: 'الصف الرابع',
          nameEn: 'Grade 4 primary',
          gradeNumber: 4,
        ),
      ];
    }
    return [
      const GradeOption(
        id: 301,
        nameAr: 'الصف الأول الثانوي',
        nameEn: 'Grade 1 secondary',
        gradeNumber: 1,
      ),
      const GradeOption(
        id: 302,
        nameAr: 'الصف الثاني الثانوي',
        nameEn: 'Grade 2 secondary',
        gradeNumber: 2,
      ),
    ];
  }

  @override
  Future<List<TrackOption>> loadTracks({
    required int programId,
    required int stageId,
    required int gradeNumber,
  }) async {
    if (stageId == 3 && gradeNumber == 2) {
      return [
        const TrackOption(
          id: 1,
          code: 'scientific',
          nameAr: 'علمي',
          nameEn: 'Scientific',
          minGradeNumber: 2,
          maxGradeNumber: 3,
        ),
      ];
    }
    return const [];
  }

  @override
  Future<List<GradeSubjectOption>> loadGradeSubjects({
    required int gradeId,
  }) async => const [];

  @override
  Future<List<TrackSubjectOption>> loadTrackSubjects({
    required int trackId,
    required int gradeId,
  }) async => const [];

  @override
  Future<List<CatalogOption>> loadGovernorates() async => [
    const CatalogOption(
      id: 1,
      code: 'cairo',
      nameAr: 'القاهرة',
      nameEn: 'Cairo',
    ),
    const CatalogOption(
      id: 2,
      code: 'giza',
      nameAr: 'الجيزة',
      nameEn: 'Giza',
    ),
  ];

  @override
  Future<List<AreaOption>> loadAreas({required int governorateId}) async => [
    AreaOption(
      id: 100,
      governorateId: governorateId,
      code: 'nasr_city',
      nameAr: 'مدينة نصر',
      nameEn: 'Nasr City',
      areaType: 'city',
    ),
  ];
}

Future<void> _pumpPage(
  WidgetTester tester,
  _FakeRegistrationRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: BlocProvider.value(
        value: _TestLocaleCubit(),
        child: StudentRegistrationPage(repository: repository),
      ),
    ),
  );
}

void main() {
  testWidgets('selecting Student opens the student registration flow', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const RoleSelectionPage()),
        GoRoute(
          path: '/register/student',
          builder: (_, _) => StudentRegistrationPage(
            repository: _FakeRegistrationRepository(),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );
    await tester.tap(find.text('Student'));
    await tester.pumpAndSettle();
    final continueFinder = find.text('Continue');
    await tester.scrollUntilVisible(
      continueFinder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text('Login data'), findsOneWidget);
    router.dispose();
  });

  testWidgets('step 1 shows phone, password, confirm, and optional email', (
    tester,
  ) async {
    await _pumpPage(tester, _FakeRegistrationRepository());
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('OTP'), findsNothing);
    expect(find.text('Verification code'), findsNothing);
  });

  testWidgets('required-field and password-match validation works', (
    tester,
  ) async {
    final repository = _FakeRegistrationRepository();
    await _pumpPage(tester, repository);
    // Phone empty, password too short, confirmation mismatched.
    await _enter(tester, find.byType(TextFormField).at(1), 'short');
    await _enter(tester, find.byType(TextFormField).at(2), 'different');
    await _tapNext(tester);
    await tester.pumpAndSettle();
    expect(find.text('Enter your phone number.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(repository.availabilityCalls, 0);
  });

  testWidgets('an empty email is allowed while an invalid one is rejected', (
    tester,
  ) async {
    final repository = _FakeRegistrationRepository()
      ..availabilityResult = const PhoneAvailability(
        status: PhoneAvailabilityStatus.available,
        phone: '+201234567890',
      );
    await _pumpPage(tester, repository);
    await _enter(tester, find.byType(TextFormField).at(0), '01234567890');
    await _enter(tester, find.byType(TextFormField).at(1), 'secret123');
    await _enter(tester, find.byType(TextFormField).at(2), 'secret123');
    await _tapNext(tester);
    await tester.pumpAndSettle();
    expect(repository.availabilityCalls, 1);
    expect(find.text('Personal data'), findsOneWidget);

    await tester.ensureVisible(find.text('Previous'));
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    await _enter(tester, find.byType(TextFormField).at(3), 'not-an-email');
    await _tapNext(tester);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(repository.availabilityCalls, 1);
  });

  testWidgets('an existing phone number blocks progression', (tester) async {
    final repository = _FakeRegistrationRepository()
      ..availabilityResult = const PhoneAvailability(
        status: PhoneAvailabilityStatus.taken,
        phone: '+201234567890',
      );
    await _pumpPage(tester, repository);
    await _enter(tester, find.byType(TextFormField).at(0), '01234567890');
    await _enter(tester, find.byType(TextFormField).at(1), 'secret123');
    await _enter(tester, find.byType(TextFormField).at(2), 'secret123');
    await _tapNext(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('This phone number is already registered. Use another number.'),
      findsOneWidget,
    );
    expect(find.text('Login data'), findsOneWidget);
    expect(repository.availabilityCalls, 1);
  });

  testWidgets('a failed availability check does not advance', (tester) async {
    final repository = _FakeRegistrationRepository();
    final completer = Completer<PhoneAvailability>();
    repository.availabilityCompleter = completer;
    await _pumpPage(tester, repository);
    await _enter(tester, find.byType(TextFormField).at(0), '01234567890');
    await _enter(tester, find.byType(TextFormField).at(1), 'secret123');
    await _enter(tester, find.byType(TextFormField).at(2), 'secret123');
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(
      find.text('Checking whether the number is available…'),
      findsOneWidget,
    );
    completer.completeError(
      const RegistrationFailure(RegistrationFailureKind.network),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('We could not check the number. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Login data'), findsOneWidget);
  });

  testWidgets('personal information validation works', (tester) async {
    await _pumpPage(tester, _FakeRegistrationRepository());
    await _completeCredentials(tester);
    await _tapNext(tester);
    await tester.pumpAndSettle();
    expect(find.text('Personal data'), findsOneWidget);
    await _tapNext(tester);
    await tester.pumpAndSettle();
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Select your date of birth.'), findsOneWidget);
    expect(find.text('Select your gender.'), findsOneWidget);
    expect(find.text('Select your governorate.'), findsOneWidget);
    expect(find.text('Select your area.'), findsOneWidget);
  });

  testWidgets('educational choices change with stage and grade', (
    tester,
  ) async {
    await _pumpPage(tester, _FakeRegistrationRepository());
    await _completeCredentials(tester);
    await _completePersonal(tester);
    await _tapNext(tester);
    await tester.pumpAndSettle();
    expect(find.text('Academic data'), findsOneWidget);

    // Pick program General
    await _pickDropdown(tester, 0, 'General');

    // Pick stage Secondary
    await _pickDropdown(tester, 1, 'Secondary');

    // The first year needs no track; the second year requires one.
    await _pickDropdown(tester, 2, 'Grade 1 secondary');
    expect(find.text('Track / specialization'), findsNothing);

    await _pickDropdown(tester, 2, 'Grade 2 secondary');
    expect(find.text('Track / specialization'), findsOneWidget);
  });

  testWidgets('changing the stage clears dependent selections', (tester) async {
    await _pumpPage(tester, _FakeRegistrationRepository());
    await _completeCredentials(tester);
    await _completePersonal(tester);
    await _tapNext(tester);

    await _pickDropdown(tester, 0, 'General');
    await _pickDropdown(tester, 1, 'Secondary');
    await _pickDropdown(tester, 2, 'Grade 2 secondary');
    await _pickDropdown(tester, 3, 'Scientific');
    expect(find.text('Scientific'), findsOneWidget);

    // Changing the stage back to primary clears the grade and track.
    await _pickDropdown(tester, 1, 'Primary');
    expect(find.text('Track / specialization'), findsNothing);
    expect(find.text('Scientific'), findsNothing);
  });

  testWidgets('back navigation preserves entered information', (tester) async {
    await _pumpPage(tester, _FakeRegistrationRepository());
    await _completeCredentials(tester);
    await _completePersonal(tester);
    // Advance to the education step, then walk back and check the values.
    await _tapNext(tester);
    expect(find.text('Academic data'), findsOneWidget);
    await tester.ensureVisible(find.text('Previous'));
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Personal data'), findsOneWidget);
    await tester.ensureVisible(find.text('Previous'));
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Login data'), findsOneWidget);
    expect(find.text('01234567890'), findsOneWidget);
  });

  testWidgets('review shows the entered data with a masked password', (
    tester,
  ) async {
    final repository = _FakeRegistrationRepository();
    await _pumpPage(tester, repository);
    await _completeCredentials(tester, email: 'student@example.com');
    await _completePersonal(tester);
    await _tapNext(tester);
    await tester.pumpAndSettle();
    await _pickDropdown(tester, 0, 'General');
    await _pickDropdown(tester, 1, 'Primary');
    await _pickDropdown(tester, 2, 'Grade 4 primary');
    await _tapNext(tester);
    await tester.pumpAndSettle();
    expect(find.text('Review your data'), findsOneWidget);
    expect(find.text('+201234567890'), findsOneWidget);
    expect(find.text('A password has been set'), findsOneWidget);
    expect(find.text('secret123'), findsNothing);
    expect(find.text('student@example.com'), findsOneWidget);
    expect(find.text('Ahmed Mohamed'), findsOneWidget);
    expect(find.text('Grade 4 primary'), findsOneWidget);
  });

  testWidgets('successful registration reaches the success screen', (
    tester,
  ) async {
    final repository = _FakeRegistrationRepository();
    await _pumpPage(tester, repository);
    await _completeCredentials(tester);
    await _completePersonal(tester);
    await _tapNext(tester);
    await tester.pumpAndSettle();
    await _pickDropdown(tester, 0, 'General');
    await _pickDropdown(tester, 1, 'Primary');
    await _pickDropdown(tester, 2, 'Grade 4 primary');
    await _tapNext(tester);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(repository.registerCalls, 1);
    expect(repository.capturedRequest?.phone, '+201234567890');
    expect(find.text('Your account has been created'), findsOneWidget);
    expect(find.text('Go to the home screen'), findsOneWidget);
  });

  testWidgets('a backend failure does not show success', (tester) async {
    final repository = _FakeRegistrationRepository()
      ..registerResult = const RegistrationFailure(
        RegistrationFailureKind.phoneAlreadyRegistered,
      );
    await _pumpPage(tester, repository);
    await _completeCredentials(tester);
    await _completePersonal(tester);
    await _tapNext(tester);
    await tester.pumpAndSettle();
    await _pickDropdown(tester, 0, 'General');
    await _pickDropdown(tester, 1, 'Primary');
    await _pickDropdown(tester, 2, 'Grade 4 primary');
    await _tapNext(tester);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Your account has been created'), findsNothing);
    await tester.ensureVisible(
      find.text('This phone number was just registered. Try another number.'),
    );
    expect(
      find.text('This phone number was just registered. Try another number.'),
      findsOneWidget,
    );
    expect(repository.registerCalls, 1);
  });

  testWidgets('repeated create taps do not submit twice', (tester) async {
    final repository = _FakeRegistrationRepository();
    final completer = Completer<void>();
    repository.registerCompleter = completer;
    await _pumpPage(tester, repository);
    await _completeCredentials(tester);
    await _completePersonal(tester);
    await _tapNext(tester);
    await tester.pumpAndSettle();
    await _pickDropdown(tester, 0, 'General');
    await _pickDropdown(tester, 1, 'Primary');
    await _pickDropdown(tester, 2, 'Grade 4 primary');
    await _tapNext(tester);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();
    // While the request is in flight the button shows a spinner and its
    // onPressed is null, so a second tap cannot reach the Cubit.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(repository.registerCalls, 1);
    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Arabic renders the flow right-to-left', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: BlocProvider.value(
          value: _TestLocaleCubit(),
          child: StudentRegistrationPage(
            repository: _FakeRegistrationRepository(),
          ),
        ),
      ),
    );
    expect(find.text('تسجيل طالب'), findsOneWidget);
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('رقم الهاتف'))),
      TextDirection.rtl,
    );
  });

  testWidgets('the teacher flow still uses the existing registration page', (
    tester,
  ) async {
    final AuthCubit authCubit = _NoopAuthCubit();
    await authCubit.restore();
    addTearDown(authCubit.close);
    // The existing email-based registration page, mounted with the provider
    // and router context it requires. It must not be the new student phone
    // flow.
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (_, _) => const RegistrationPage(role: 'teacher'),
        ),
      ],
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: authCubit,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Phone number'), findsNothing);
    expect(find.text('Confirm password'), findsNothing);
    router.dispose();
  });
}

Future<void> _completeCredentials(
  WidgetTester tester, {
  String email = '',
}) async {
  await _enter(tester, find.byType(TextFormField).at(0), '01234567890');
  await _enter(tester, find.byType(TextFormField).at(1), 'secret123');
  await _enter(tester, find.byType(TextFormField).at(2), 'secret123');
  if (email.isNotEmpty) {
    await _enter(tester, find.byType(TextFormField).at(3), email);
  }
  await _tapNext(tester);
}

/// Enters text into a field, scrolling it into view first.
Future<void> _enter(WidgetTester tester, Finder finder, String text) async {
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
}

/// Taps the primary action, scrolling it into view first.
Future<void> _tapNext(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Next'));
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

/// Opens the [index]-th dropdown on screen and picks [option].
///
/// Flutter's type finder requires the exact runtime generic type, and the
/// education step uses a different generic type per field, so this matches
/// any DropdownButtonFormField regardless of its type argument and selects
/// by position.
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
  // The dropdown field itself is not reliably tappable in this test setup;
  // tapping the trailing arrow icon opens the menu.
  final arrow = find.descendant(
    of: target,
    matching: find.byIcon(Icons.arrow_drop_down),
  );
  await tester.tap(arrow, warnIfMissed: false);
  // A modal dropdown menu never reaches a "settled" state under
  // pumpAndSettle in this test setup, so pump explicitly instead.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  final item = find.text(option).last;
  await tester.ensureVisible(item);
  await tester.tap(item, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _completePersonal(WidgetTester tester) async {
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
}

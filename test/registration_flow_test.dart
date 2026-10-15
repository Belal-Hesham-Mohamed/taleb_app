import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taleb/app/pages/auth_pages.dart';
import 'package:taleb/app/router/auth_redirect_policy.dart';
import 'package:taleb/core/errors/failure.dart';
import 'package:taleb/features/auth/domain/entities/account_role.dart';
import 'package:taleb/features/auth/domain/entities/user_profile.dart';
import 'package:taleb/features/auth/domain/repositories/auth_repository.dart';
import 'package:taleb/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:taleb/l10n/app_localizations.dart';

void main() {
  testWidgets('validates required fields before advancing', (tester) async {
    final harness = await _TestHarness.create(tester, _FakeAuthRepository());
    addTearDown(harness.dispose);

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(harness.repository.signUpCalls, 0);
  });

  testWidgets('successful student registration reaches student home', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..signUpResult = const Right(
        UserProfile(
          id: 'student-1',
          email: 'sam@example.com',
          fullName: 'Sam Student',
          role: AccountRole.student,
        ),
      );
    final harness = await _TestHarness.create(tester, repository);
    addTearDown(harness.dispose);

    await _enterCredentials(tester);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 2'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextFormField).at(0));
    await tester.enterText(find.byType(TextFormField).at(0), 'Nile School');
    await tester.ensureVisible(find.byType(TextFormField).at(1));
    await tester.enterText(find.byType(TextFormField).at(1), 'Grade 7');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(repository.signUpCalls, 1);
    expect(repository.capturedEmail, 'sam@example.com');
    expect(repository.capturedPassword, 'long-password');
    expect(repository.capturedFullName, 'Sam Student');
    expect(repository.capturedRole, AccountRole.student);
    expect(repository.capturedSchool, 'Nile School');
    expect(repository.capturedGrade, 'Grade 7');
    expect(find.text('Student space'), findsOneWidget);
  });

  testWidgets('backend error keeps registration data available to edit', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final pending = Completer<Either<Failure, UserProfile?>>();
    repository.signUpCompleter = pending;
    final harness = await _TestHarness.create(tester, repository);
    addTearDown(harness.dispose);

    await _enterCredentials(tester);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 2'), findsOneWidget);
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('School (optional)'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.signUpCalls, 1);

    pending.complete(const Left(Failure(FailureKind.network)));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to connect. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Create account'), findsOneWidget);
    await tester.ensureVisible(find.text('Back'));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Sam Student',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      ' sam@example.com ',
    );
  });
}

Future<void> _enterCredentials(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(TextFormField).at(0));
  await tester.enterText(find.byType(TextFormField).at(0), 'Sam Student');
  await tester.ensureVisible(find.byType(TextFormField).at(1));
  await tester.enterText(find.byType(TextFormField).at(1), ' sam@example.com ');
  await tester.ensureVisible(find.byType(TextFormField).at(2));
  await tester.enterText(find.byType(TextFormField).at(2), 'long-password');
  await tester.pump();
}

class _TestHarness {
  _TestHarness(this.repository, this.cubit, this.router, this.refresh);

  final _FakeAuthRepository repository;
  final AuthCubit cubit;
  final GoRouter router;
  final _AuthRouterRefresh refresh;

  static Future<_TestHarness> create(
    WidgetTester tester,
    _FakeAuthRepository repository,
  ) async {
    final cubit = AuthCubit(repository);
    await cubit.restore();
    final refresh = _AuthRouterRefresh(cubit);
    final router = GoRouter(
      initialLocation: '/register?role=student',
      refreshListenable: refresh,
      redirect: (_, state) =>
          resolveAuthRedirect(cubit.state, state.matchedLocation),
      routes: [
        GoRoute(
          path: '/register',
          builder: (_, state) => RegistrationPage(
            role: state.uri.queryParameters['role'] ?? 'student',
          ),
        ),
        GoRoute(
          path: '/loading',
          builder: (_, _) => const Text('loading-route'),
        ),
        GoRoute(
          path: '/confirm-email',
          builder: (_, _) => const ConfirmEmailPage(),
        ),
        GoRoute(path: '/home', builder: (_, _) => const HomePage()),
      ],
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    return _TestHarness(repository, cubit, router, refresh);
  }

  Future<void> dispose() async {
    router.dispose();
    refresh.dispose();
    await cubit.close();
    await repository.controller.close();
  }
}

class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(AuthCubit cubit) {
    _subscription = cubit.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _FakeAuthRepository implements AuthRepository {
  final controller = StreamController<AuthChange>.broadcast();
  Either<Failure, UserProfile?> signUpResult = const Right(null);
  Completer<Either<Failure, UserProfile?>>? signUpCompleter;
  int signUpCalls = 0;
  String? capturedEmail;
  String? capturedPassword;
  String? capturedFullName;
  AccountRole? capturedRole;
  String? capturedSchool;
  String? capturedGrade;

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
  }) {
    signUpCalls++;
    capturedEmail = email;
    capturedPassword = password;
    capturedFullName = fullName;
    capturedRole = role;
    capturedSchool = school;
    capturedGrade = grade;
    return signUpCompleter?.future ?? Future.value(signUpResult);
  }

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

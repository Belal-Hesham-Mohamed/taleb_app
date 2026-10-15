import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/core/errors/failure.dart';
import 'package:taleb/features/auth/domain/entities/account_role.dart';
import 'package:taleb/features/auth/domain/entities/user_profile.dart';
import 'package:taleb/features/auth/domain/repositories/auth_repository.dart';
import 'package:taleb/features/auth/presentation/cubit/auth_cubit.dart';

void main() {
  late _FakeAuthRepository repository;
  late AuthCubit cubit;

  setUp(() {
    repository = _FakeAuthRepository();
    cubit = AuthCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
    await repository.controller.close();
  });

  test('restores a profile-backed session', () async {
    repository.profile = const UserProfile(
      id: 'user-1',
      email: 'student@example.com',
      fullName: 'Student',
      role: AccountRole.student,
    );
    await cubit.restore();
    expect(cubit.state.status, AuthStatus.signedIn);
    expect(cubit.state.profile?.role, AccountRole.student);
  });

  test('distinguishes session restoration from an auth action', () async {
    final completer = Completer<Either<Failure, UserProfile?>>();
    repository.restoreCompleter = completer;

    final restoring = cubit.restore();
    expect(cubit.state.status, AuthStatus.restoring);

    completer.complete(const Right(null));
    await restoring;
    expect(cubit.state.status, AuthStatus.signedOut);
  });

  test('maps invalid credentials into the signed-out state', () async {
    repository.signInResult = const Left(
      Failure(FailureKind.invalidCredentials),
    );
    await cubit.signIn('bad@example.com', 'wrong-password');
    expect(cubit.state.status, AuthStatus.signedOut);
    expect(cubit.state.failure?.kind, FailureKind.invalidCredentials);
  });

  test(
    'keeps a session in profile-failure state when restore cannot load profile',
    () async {
      repository.restoreResult = const Left(
        Failure(FailureKind.profileNotFound),
      );
      await cubit.restore();
      expect(cubit.state.status, AuthStatus.profileFailure);
      expect(cubit.state.failure?.kind, FailureKind.profileNotFound);
    },
  );

  test(
    'does not treat a post-login profile fetch failure as signed out',
    () async {
      repository.signInResult = const Left(
        Failure(FailureKind.profileUnavailable),
      );
      await cubit.signIn('student@example.com', 'correct-password');
      expect(cubit.state.status, AuthStatus.profileFailure);
      expect(cubit.state.failure?.kind, FailureKind.profileUnavailable);
    },
  );

  test('does not submit a second request while one is pending', () async {
    final completer = Completer<Either<Failure, UserProfile>>();
    repository.signInCompleter = completer;
    final first = cubit.signIn('a@example.com', 'password1');
    await cubit.signIn('b@example.com', 'password2');
    expect(repository.signInCalls, 1);
    completer.complete(
      Right(
        const UserProfile(
          id: 'user-1',
          email: 'a@example.com',
          fullName: 'A',
          role: AccountRole.student,
        ),
      ),
    );
    await first;
    expect(cubit.state.status, AuthStatus.signedIn);
  });

  test(
    'signup initialization failure is surfaced and does not report success',
    () async {
      repository.signUpResult = const Left(Failure(FailureKind.unknown));
      await cubit.signUp(
        email: 'new@example.com',
        password: 'long-password',
        fullName: 'New User',
        role: AccountRole.student,
      );
      expect(cubit.state.status, AuthStatus.signedOut);
      expect(cubit.state.failure?.kind, FailureKind.unknown);
    },
  );

  test(
    'does not submit a second registration while the first is pending',
    () async {
      final completer = Completer<Either<Failure, UserProfile?>>();
      repository.signUpCompleter = completer;

      final first = cubit.signUp(
        email: 'new@example.com',
        password: 'long-password',
        fullName: 'New User',
        role: AccountRole.student,
      );
      await cubit.signUp(
        email: 'other@example.com',
        password: 'long-password',
        fullName: 'Other User',
        role: AccountRole.student,
      );
      expect(repository.signUpCalls, 1);

      completer.complete(const Right(null));
      await first;
      expect(cubit.state.status, AuthStatus.needsEmailConfirmation);
    },
  );

  test('loads the student profile when email confirmation signs in', () async {
    const profile = UserProfile(
      id: 'student-1',
      email: 'student@example.com',
      fullName: 'Student',
      role: AccountRole.student,
    );
    repository.signUpResult = const Right(null);
    repository.currentProfileResult = const Right(profile);

    await cubit.signUp(
      email: profile.email,
      password: 'long-password',
      fullName: profile.fullName,
      role: profile.role,
    );
    expect(cubit.state.status, AuthStatus.needsEmailConfirmation);

    repository.controller.add(AuthChange.signedIn);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, AuthStatus.signedIn);
    expect(cubit.state.profile?.role, AccountRole.student);
  });

  test('signout failure preserves the active session state', () async {
    const profile = UserProfile(
      id: 'user-1',
      email: 'student@example.com',
      fullName: 'Student',
      role: AccountRole.student,
    );
    repository.signInResult = const Right(profile);
    await cubit.signIn(profile.email, 'long-password');
    repository.signOutResult = const Left(Failure(FailureKind.network));
    await cubit.signOut();
    expect(cubit.state.status, AuthStatus.signedIn);
    expect(cubit.state.failure?.kind, FailureKind.network);
  });

  test('signed-out auth event clears a profile-error session', () async {
    repository.restoreResult = const Left(Failure(FailureKind.profileNotFound));
    await cubit.restore();
    repository.controller.add(AuthChange.signedOut);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, AuthStatus.signedOut);
  });

  test(
    'password update profile failure does not report a signed-out session',
    () async {
      repository.currentProfileResult = const Left(
        Failure(FailureKind.profileUnavailable),
      );
      repository.controller.add(AuthChange.passwordRecovery);
      await Future<void>.delayed(Duration.zero);
      await cubit.updatePassword('new-long-password');
      expect(cubit.state.status, AuthStatus.profileFailure);
      expect(cubit.state.failure?.kind, FailureKind.profileUnavailable);
    },
  );
}

class _FakeAuthRepository implements AuthRepository {
  final controller = StreamController<AuthChange>.broadcast();
  UserProfile? profile;
  Either<Failure, UserProfile?>? restoreResult;
  Completer<Either<Failure, UserProfile?>>? restoreCompleter;
  Either<Failure, UserProfile>? currentProfileResult;
  Either<Failure, UserProfile> signInResult = const Left(
    Failure(FailureKind.invalidCredentials),
  );
  Either<Failure, UserProfile?> signUpResult = const Right(null);
  Either<Failure, Unit> signOutResult = const Right(unit);
  Completer<Either<Failure, UserProfile>>? signInCompleter;
  Completer<Either<Failure, UserProfile?>>? signUpCompleter;
  int signInCalls = 0;
  int signUpCalls = 0;

  @override
  Stream<AuthChange> get authChanges => controller.stream;
  @override
  Future<Either<Failure, UserProfile?>> restoreSession() =>
      restoreCompleter?.future ?? Future.value(restoreResult ?? Right(profile));
  @override
  Future<Either<Failure, UserProfile>> signIn(String email, String password) {
    signInCalls++;
    return signInCompleter?.future ?? Future.value(signInResult);
  }

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
    return signUpCompleter?.future ?? Future.value(signUpResult);
  }

  @override
  Future<Either<Failure, Unit>> signOut() async => signOutResult;
  @override
  Future<Either<Failure, UserProfile>> currentProfile() async =>
      currentProfileResult ??
      (profile == null
          ? const Left(Failure(FailureKind.profileNotFound))
          : Right(profile!));
  @override
  Future<Either<Failure, Unit>> requestPasswordReset(String email) async =>
      const Right(unit);
  @override
  Future<Either<Failure, Unit>> updatePassword(String password) async =>
      const Right(unit);
}

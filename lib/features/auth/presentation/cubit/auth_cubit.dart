import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/account_role.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  restoring,
  loading,
  signedOut,
  signedIn,
  needsEmailConfirmation,
  passwordRecovery,
  profileFailure,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.profile,
    this.failure,
    this.notice,
  });

  final AuthStatus status;
  final UserProfile? profile;
  final Failure? failure;
  final String? notice;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? profile,
    Failure? failure,
    String? notice,
    bool clearFailure = false,
  }) => AuthState(
    status: status ?? this.status,
    profile: profile ?? this.profile,
    failure: clearFailure ? null : failure ?? this.failure,
    notice: notice,
  );
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState()) {
    _authSubscription = _repository.authChanges.listen((change) {
      if (change == AuthChange.passwordRecovery) {
        emit(const AuthState(status: AuthStatus.passwordRecovery));
      } else if (change == AuthChange.signedOut) {
        if (state.status == AuthStatus.signedIn ||
            state.status == AuthStatus.profileFailure ||
            state.status == AuthStatus.passwordRecovery) {
          emit(const AuthState(status: AuthStatus.signedOut));
        }
      } else if (change == AuthChange.signedIn &&
          (state.status == AuthStatus.signedOut ||
              state.status == AuthStatus.profileFailure ||
              state.status == AuthStatus.needsEmailConfirmation) &&
          !_busy) {
        _loadCurrentProfile();
      }
    });
  }
  final AuthRepository _repository;
  late final StreamSubscription<AuthChange> _authSubscription;
  bool _busy = false;

  Future<void> _loadCurrentProfile() async {
    final result = await _repository.currentProfile();
    result.fold(
      (failure) => emit(_profileFailureState(failure)),
      (profile) =>
          emit(AuthState(status: AuthStatus.signedIn, profile: profile)),
    );
  }

  AuthState _profileFailureState(Failure failure) => AuthState(
    status: failure.kind == FailureKind.sessionExpired
        ? AuthStatus.signedOut
        : AuthStatus.profileFailure,
    failure: failure,
  );

  bool _isProfileFailure(Failure failure) =>
      failure.kind == FailureKind.profileNotFound ||
      failure.kind == FailureKind.profileUnavailable;

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }

  Future<void> restore() async {
    if (_busy) return;
    _busy = true;
    emit(state.copyWith(status: AuthStatus.restoring, clearFailure: true));
    final result = await _repository.restoreSession();
    result.fold(
      (failure) => emit(_profileFailureState(failure)),
      (profile) => emit(
        AuthState(
          status: profile == null ? AuthStatus.signedOut : AuthStatus.signedIn,
          profile: profile,
        ),
      ),
    );
    _busy = false;
  }

  Future<void> signIn(String email, String password) async {
    if (_busy) return;
    _busy = true;
    emit(state.copyWith(status: AuthStatus.loading, clearFailure: true));
    final result = await _repository.signIn(email.trim(), password);
    result.fold(
      (failure) => emit(
        _isProfileFailure(failure)
            ? _profileFailureState(failure)
            : AuthState(status: AuthStatus.signedOut, failure: failure),
      ),
      (profile) =>
          emit(AuthState(status: AuthStatus.signedIn, profile: profile)),
    );
    _busy = false;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required AccountRole role,
    String? school,
    String? grade,
  }) async {
    if (_busy) return;
    _busy = true;
    emit(state.copyWith(status: AuthStatus.loading, clearFailure: true));
    final result = await _repository.signUp(
      email: email.trim(),
      password: password,
      fullName: fullName,
      role: role,
      school: school,
      grade: grade,
    );
    result.fold(
      (failure) => emit(
        _isProfileFailure(failure)
            ? _profileFailureState(failure)
            : AuthState(status: AuthStatus.signedOut, failure: failure),
      ),
      (profile) => emit(
        AuthState(
          status: profile == null
              ? AuthStatus.needsEmailConfirmation
              : AuthStatus.signedIn,
          profile: profile,
        ),
      ),
    );
    _busy = false;
  }

  Future<void> signOut() async {
    if (_busy) return;
    _busy = true;
    final result = await _repository.signOut();
    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (_) => emit(const AuthState(status: AuthStatus.signedOut)),
    );
    _busy = false;
  }

  Future<void> retryProfile() => restore();

  Future<void> requestPasswordReset(String email) async {
    if (_busy) return;
    _busy = true;
    emit(state.copyWith(status: AuthStatus.loading, clearFailure: true));
    final result = await _repository.requestPasswordReset(email.trim());
    result.fold(
      (failure) =>
          emit(state.copyWith(status: AuthStatus.signedOut, failure: failure)),
      (_) => emit(
        state.copyWith(status: AuthStatus.signedOut, notice: 'resetSent'),
      ),
    );
    _busy = false;
  }

  Future<void> updatePassword(String password) async {
    if (_busy) return;
    _busy = true;
    emit(state.copyWith(status: AuthStatus.loading, clearFailure: true));
    final result = await _repository.updatePassword(password);
    if (result.isLeft()) {
      result.fold(
        (failure) => emit(
          state.copyWith(status: AuthStatus.passwordRecovery, failure: failure),
        ),
        (_) {},
      );
    } else {
      final profileResult = await _repository.currentProfile();
      profileResult.fold(
        (failure) => emit(_profileFailureState(failure)),
        (profile) => emit(
          AuthState(
            status: AuthStatus.signedIn,
            profile: profile,
            notice: 'passwordUpdated',
          ),
        ),
      );
    }
    _busy = false;
  }
}

import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/account_role.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/profile_model.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);
  final SupabaseClient _client;

  @override
  Stream<AuthChange> get authChanges => _client.auth.onAuthStateChange.map((
    event,
  ) {
    if (event.event == AuthChangeEvent.passwordRecovery) {
      return AuthChange.passwordRecovery;
    }
    return event.session == null ? AuthChange.signedOut : AuthChange.signedIn;
  });

  @override
  Future<Either<Failure, UserProfile?>> restoreSession() async {
    if (_client.auth.currentSession == null) return const Right(null);
    return currentProfile().then(
      (result) =>
          result.fold((failure) => Left(failure), (profile) => Right(profile)),
    );
  }

  @override
  Future<Either<Failure, UserProfile>> signIn(
    String email,
    String password,
  ) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return currentProfile();
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> signUp({
    required String email,
    required String password,
    required String fullName,
    required AccountRole role,
    String? school,
    String? grade,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'role': role.value,
          if (school?.trim().isNotEmpty ?? false) 'school': school!.trim(),
          if (grade?.trim().isNotEmpty ?? false) 'grade': grade!.trim(),
        },
      );
      if (response.session == null) return const Right(null);
      return currentProfile().then(
        (result) => result.fold(
          (failure) => Left(failure),
          (profile) => Right(profile),
        ),
      );
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> currentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return const Left(Failure(FailureKind.sessionExpired));
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return Right(ProfileModel.fromMap(data));
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST116') {
        return const Left(Failure(FailureKind.profileNotFound));
      }
      return const Left(Failure(FailureKind.profileUnavailable));
    } catch (error) {
      return const Left(Failure(FailureKind.profileUnavailable));
    }
  }

  @override
  Future<Either<Failure, Unit>> requestPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  Failure _mapError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login') ||
          message.contains('credentials')) {
        return const Failure(FailureKind.invalidCredentials);
      }
      if (message.contains('already registered') ||
          message.contains('already been registered')) {
        return const Failure(FailureKind.emailAlreadyRegistered);
      }
    }
    if (error is PostgrestException) {
      if (error.code == 'PGRST116') {
        return const Failure(FailureKind.profileNotFound);
      }
      if (error.code == '42501') return const Failure(FailureKind.unknown);
    }
    if (error is SocketException) return const Failure(FailureKind.network);
    return const Failure(FailureKind.unknown);
  }
}

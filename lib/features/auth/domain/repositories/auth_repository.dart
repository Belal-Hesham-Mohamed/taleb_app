import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/account_role.dart';
import '../entities/user_profile.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, UserProfile?>> restoreSession();
  Stream<AuthChange> get authChanges;
  Future<Either<Failure, UserProfile>> signIn(String email, String password);
  Future<Either<Failure, UserProfile?>> signUp({
    required String email,
    required String password,
    required String fullName,
    required AccountRole role,
    String? school,
    String? grade,
  });
  Future<Either<Failure, Unit>> signOut();
  Future<Either<Failure, UserProfile>> currentProfile();
  Future<Either<Failure, Unit>> requestPasswordReset(String email);
  Future<Either<Failure, Unit>> updatePassword(String password);
}

enum AuthChange { signedIn, signedOut, passwordRecovery }

import '../../features/auth/domain/entities/account_role.dart';
import '../../features/auth/domain/entities/user_profile.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

String? resolveAuthRedirect(AuthState auth, String location) {
  if (location == '/invalid-link') return null;
  if (auth.status == AuthStatus.passwordRecovery) {
    return location == '/password-update' ? null : '/password-update';
  }
  if (location == '/password-update' &&
      auth.status != AuthStatus.passwordRecovery &&
      auth.status != AuthStatus.loading &&
      auth.status != AuthStatus.restoring) {
    return '/';
  }
  if (auth.status == AuthStatus.profileFailure) {
    return location == '/profile-unavailable' ? null : '/profile-unavailable';
  }
  if (location == '/profile-unavailable' &&
      auth.status != AuthStatus.loading &&
      auth.status != AuthStatus.restoring) {
    return '/';
  }

  final isPublic = {
    '/',
    '/sign-in',
    '/register',
    '/register/student',
    '/roles',
    '/reset',
    '/invalid-link',
    '/confirm-email',
  }.contains(location);

  if (auth.status == AuthStatus.initial ||
      auth.status == AuthStatus.restoring) {
    return location == '/loading' ? null : '/loading';
  }
  if (auth.status == AuthStatus.loading) {
    if (isPublic ||
        location == '/loading' ||
        location == '/password-update' ||
        location == '/profile-unavailable') {
      return null;
    }
    return '/loading';
  }
  if (auth.status == AuthStatus.signedIn) {
    if (isPublic ||
        location == '/loading' ||
        location == '/profile-unavailable') {
      return auth.profile?.role == AccountRole.teacher &&
              auth.profile?.teacherStatus != TeacherStatus.approved
          ? '/pending'
          : '/home';
    }
    if (location == '/pending' &&
        auth.profile?.teacherStatus == TeacherStatus.approved) {
      return '/home';
    }
    return null;
  }
  if (auth.status == AuthStatus.needsEmailConfirmation) {
    return location == '/confirm-email' ? null : '/confirm-email';
  }
  if (!isPublic && location != '/loading') return '/';
  return location == '/loading' ? '/' : null;
}

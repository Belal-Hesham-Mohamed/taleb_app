import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/app/router/auth_redirect_policy.dart';
import 'package:taleb/features/auth/domain/entities/account_role.dart';
import 'package:taleb/features/auth/domain/entities/user_profile.dart';
import 'package:taleb/features/auth/presentation/cubit/auth_cubit.dart';

void main() {
  test('students and guardians go to home after sign-in', () {
    for (final role in [AccountRole.student, AccountRole.guardian]) {
      final auth = AuthState(
        status: AuthStatus.signedIn,
        profile: UserProfile(
          id: 'u',
          email: 'user@example.com',
          fullName: 'User',
          role: role,
        ),
      );
      expect(resolveAuthRedirect(auth, '/sign-in'), '/home');
    }
  });

  test('teacher review status controls the destination', () {
    final pendingTeacher = AuthState(
      status: AuthStatus.signedIn,
      profile: const UserProfile(
        id: 't',
        email: 'teacher@example.com',
        fullName: 'Teacher',
        role: AccountRole.teacher,
        teacherStatus: TeacherStatus.pending,
      ),
    );
    final approvedTeacher = AuthState(
      status: AuthStatus.signedIn,
      profile: const UserProfile(
        id: 't',
        email: 'teacher@example.com',
        fullName: 'Teacher',
        role: AccountRole.teacher,
        teacherStatus: TeacherStatus.approved,
      ),
    );
    final rejectedTeacher = AuthState(
      status: AuthStatus.signedIn,
      profile: const UserProfile(
        id: 't',
        email: 'teacher@example.com',
        fullName: 'Teacher',
        role: AccountRole.teacher,
        teacherStatus: TeacherStatus.rejected,
        rejectionReason: 'Please provide a school name.',
      ),
    );
    expect(resolveAuthRedirect(pendingTeacher, '/sign-in'), '/pending');
    expect(resolveAuthRedirect(approvedTeacher, '/sign-in'), '/home');
    expect(resolveAuthRedirect(approvedTeacher, '/pending'), '/home');
    expect(resolveAuthRedirect(rejectedTeacher, '/sign-in'), '/pending');
  });

  test(
    'profile failure is recoverable and remains separate from signed-out',
    () {
      const auth = AuthState(status: AuthStatus.profileFailure);
      expect(resolveAuthRedirect(auth, '/home'), '/profile-unavailable');
      expect(resolveAuthRedirect(auth, '/profile-unavailable'), isNull);
    },
  );
}

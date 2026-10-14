import 'account_role.dart';

enum TeacherStatus { pending, approved, rejected }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.teacherStatus,
    this.rejectionReason,
  });

  final String id;
  final String email;
  final String fullName;
  final AccountRole role;
  final TeacherStatus? teacherStatus;
  final String? rejectionReason;
}

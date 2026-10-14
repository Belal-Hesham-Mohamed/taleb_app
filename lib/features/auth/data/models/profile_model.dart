import '../../domain/entities/account_role.dart';
import '../../domain/entities/user_profile.dart';

class ProfileModel extends UserProfile {
  const ProfileModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.teacherStatus,
    super.rejectionReason,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    final role = AccountRoleValue.parse(map['role'] as String?);
    if (role == null) throw const FormatException('Unsupported profile role');
    return ProfileModel(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      role: role,
      teacherStatus: map['role'] == 'teacher'
          ? TeacherStatus.values.firstWhere(
              (status) => status.name == map['teacher_status'],
              orElse: () => TeacherStatus.pending,
            )
          : null,
      rejectionReason: map['rejection_reason'] as String?,
    );
  }
}

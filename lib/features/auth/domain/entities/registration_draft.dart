import '../validation/phone_number.dart';
import 'education_path.dart';

/// A student gender value.
enum Gender {
  male,
  female;

  static Gender? parse(String? value) {
    for (final gender in Gender.values) {
      if (gender.name == value) return gender;
    }
    return null;
  }
}

/// A sentinel value that distinguishes "argument not provided" from "explicitly
/// null", which lets [RegistrationDraft.copyWith] clear a nullable selection.
const Object _absent = Object();

/// The data collected by the student registration journey.
///
/// Selections are stored as stable identifiers ([EducationalStage],
/// [EducationType], [AcademicSystem], [StudyGrade], [AcademicTrack]) and are
/// only turned into localized labels at presentation time. The password is
/// held only in memory for the duration of the flow: this object is never
/// serialized, persisted, or logged.
class RegistrationDraft {
  const RegistrationDraft({
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.email,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.studentId,
    required this.guardianPhone,
    required this.guardianId,
    required this.governorate,
    required this.area,
    required this.stage,
    required this.type,
    required this.system,
    required this.grade,
    required this.track,
    required this.school,
  });

  const RegistrationDraft.empty()
    : phone = '',
      password = '',
      confirmPassword = '',
      email = '',
      fullName = '',
      dateOfBirth = '',
      gender = null,
      studentId = '',
      guardianPhone = '',
      guardianId = '',
      governorate = '',
      area = '',
      stage = null,
      type = null,
      system = null,
      grade = null,
      track = null,
      school = '';

  final String phone;
  final String password;
  final String confirmPassword;
  final String email;
  final String fullName;
  final String dateOfBirth;
  final Gender? gender;
  final String studentId;
  final String guardianPhone;
  final String guardianId;
  final String governorate;
  final String area;
  final EducationalStage? stage;
  final EducationType? type;
  final AcademicSystem? system;
  final StudyGrade? grade;
  final AcademicTrack? track;
  final String school;

  /// The phone number in E.164, or `null` when it cannot be normalized.
  String? get normalizedPhone => normalizePhoneNumber(phone);

  /// A masked display of the password that never reveals its value.
  String get maskedPassword => password.isEmpty ? '' : '•' * password.length;

  /// Whether the selected path needs an academic track at all.
  bool get requiresTrack {
    final system = this.system;
    final grade = this.grade;
    if (system == null || grade == null) return false;
    return requiresAcademicTrack(system, grade);
  }

  /// Returns a copy with the provided values replaced.
  ///
  /// Nullable fields use a sentinel so that explicitly passing `null` clears
  /// the field: without it a dependent selection could never be reset by a
  /// parent change.
  RegistrationDraft copyWith({
    String? phone,
    String? password,
    String? confirmPassword,
    String? email,
    String? fullName,
    String? dateOfBirth,
    Gender? gender,
    String? studentId,
    String? guardianPhone,
    String? guardianId,
    String? governorate,
    String? area,
    EducationalStage? stage,
    EducationType? type,
    AcademicSystem? system,
    StudyGrade? grade,
    AcademicTrack? track,
    String? school,
    Object? clearGender = _absent,
    Object? clearType = _absent,
    Object? clearSystem = _absent,
    Object? clearGrade = _absent,
    Object? clearTrack = _absent,
  }) => RegistrationDraft(
    phone: phone ?? this.phone,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    email: email ?? this.email,
    fullName: fullName ?? this.fullName,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: clearGender == _absent ? (gender ?? this.gender) : null,
    studentId: studentId ?? this.studentId,
    guardianPhone: guardianPhone ?? this.guardianPhone,
    guardianId: guardianId ?? this.guardianId,
    governorate: governorate ?? this.governorate,
    area: area ?? this.area,
    stage: stage ?? this.stage,
    type: clearType == _absent ? (type ?? this.type) : null,
    system: clearSystem == _absent ? (system ?? this.system) : null,
    grade: clearGrade == _absent ? (grade ?? this.grade) : null,
    track: clearTrack == _absent ? (track ?? this.track) : null,
    school: school ?? this.school,
  );

  /// Replaces the stage and clears every dependent selection.
  RegistrationDraft withStage(EducationalStage stage) => copyWith(
    stage: stage,
    clearType: true,
    clearSystem: true,
    clearGrade: true,
    clearTrack: true,
  );

  /// Replaces the education type and clears the dependent system and track.
  RegistrationDraft withType(EducationType type) =>
      copyWith(type: type, clearSystem: true, clearTrack: true);

  /// Replaces the academic system and clears the track, which must be
  /// re-selected because the valid tracks differ between systems.
  RegistrationDraft withSystem(AcademicSystem system) =>
      copyWith(system: system, clearTrack: true);

  /// Replaces the grade and clears the track, which must be re-selected
  /// because the valid tracks differ between grades.
  RegistrationDraft withGrade(StudyGrade grade) =>
      copyWith(grade: grade, clearTrack: true);
}

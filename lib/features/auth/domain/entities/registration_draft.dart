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
/// Education and location selections are stored as **database ids**
/// ([programId], [stageId], [gradeId], [trackId], [governorateId],
/// [areaId]) because the catalog is the source of truth; the legacy text
/// fields ([governorate], [area], [stage], [type], [system], [grade],
/// [track]) are preserved so existing rows and older clients keep working.
/// Display labels are never stored: they are resolved from the catalog at
/// presentation time.
///
/// The password is held only in memory for the duration of the flow: this
/// object is never serialized, persisted, or logged.
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
    this.programId,
    this.stageId,
    this.gradeId,
    this.trackId,
    this.gradeNumber,
    this.governorateId,
    this.areaId,
    this.schoolName = '',
    this.schoolType = '',
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
      school = '',
      programId = null,
      stageId = null,
      gradeId = null,
      trackId = null,
      gradeNumber = null,
      governorateId = null,
      areaId = null,
      schoolName = '',
      schoolType = '';

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

  /// Legacy text location fields, kept for backward compatibility.
  final String governorate;
  final String area;

  /// Legacy text education fields, kept for backward compatibility.
  final EducationalStage? stage;
  final EducationType? type;
  final AcademicSystem? system;
  final StudyGrade? grade;
  final AcademicTrack? track;
  final String school;

  /// The education program id from `education_programs`.
  final int? programId;

  /// The education stage id from `education_stages`.
  final int? stageId;

  /// The education grade id from `education_grades`.
  final int? gradeId;

  /// The education track id from `education_tracks`, when a track applies.
  final int? trackId;

  /// The numeric grade, used for track applicability. Never the display name.
  final int? gradeNumber;

  /// The governorate id from `governorates`.
  final int? governorateId;

  /// The area id from `areas`. Belongs to [governorateId] by the database
  /// relationship, so an area from another governorate can never be stored.
  final int? areaId;

  /// Optional school name. Never required.
  final String schoolName;
  final String schoolType;

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

  /// The verified `student_profiles` columns this draft persists.
  ///
  /// Null foreign keys and empty optional fields are omitted entirely, so the
  /// database default (null) applies and the school name stays optional. The
  /// password is never included.
  Map<String, dynamic> toProfilePayload() {
    final payload = <String, dynamic>{
      if (phone.trim().isNotEmpty) 'phone': normalizedPhone ?? phone.trim(),
      if (dateOfBirth.trim().isNotEmpty) 'date_of_birth': dateOfBirth.trim(),
      if (gender != null) 'gender': gender!.name,
      if (studentId.trim().isNotEmpty) 'student_id': studentId.trim(),
      if (guardianPhone.trim().isNotEmpty)
        'guardian_phone':
            normalizePhoneNumber(guardianPhone) ?? guardianPhone.trim(),
      if (guardianId.trim().isNotEmpty) 'guardian_id': guardianId.trim(),
      // Legacy text columns, preserved for older rows and clients.
      if (governorate.trim().isNotEmpty) 'governorate': governorate.trim(),
      if (area.trim().isNotEmpty) 'area': area.trim(),
      if (stage != null) 'education_stage': stage!.name,
      if (type != null) 'education_type': type!.name,
      if (system != null) 'academic_system': system!.name,
      if (grade != null) 'grade': grade!.name,
      if (track != null) 'academic_track': track!.name,
      // Relational columns: the authoritative references.
      if (programId != null) 'education_program_id': programId,
      if (gradeId != null) 'education_grade_id': gradeId,
      if (trackId != null) 'education_track_id': trackId,
      if (areaId != null) 'area_id': areaId,
      if (schoolName.trim().isNotEmpty) 'school_name': schoolName.trim(),
      if (schoolType.trim().isNotEmpty) 'school_type': schoolType.trim(),
      if (school.trim().isNotEmpty) 'school': school.trim(),
    };
    return payload;
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
    int? programId,
    int? stageId,
    int? gradeId,
    int? trackId,
    int? gradeNumber,
    int? governorateId,
    int? areaId,
    String? schoolName,
    String? schoolType,
    Object? clearGender = _absent,
    Object? clearType = _absent,
    Object? clearSystem = _absent,
    Object? clearGrade = _absent,
    Object? clearTrack = _absent,
    Object? clearProgramId = _absent,
    Object? clearStageId = _absent,
    Object? clearGradeId = _absent,
    Object? clearTrackId = _absent,
    Object? clearGovernorateId = _absent,
    Object? clearAreaId = _absent,
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
    programId: clearProgramId == _absent ? (programId ?? this.programId) : null,
    stageId: clearStageId == _absent ? (stageId ?? this.stageId) : null,
    gradeId: clearGradeId == _absent ? (gradeId ?? this.gradeId) : null,
    trackId: clearTrackId == _absent ? (trackId ?? this.trackId) : null,
    gradeNumber: gradeNumber ?? this.gradeNumber,
    governorateId: clearGovernorateId == _absent
        ? (governorateId ?? this.governorateId)
        : null,
    areaId: clearAreaId == _absent ? (areaId ?? this.areaId) : null,
    schoolName: schoolName ?? this.schoolName,
    schoolType: schoolType ?? this.schoolType,
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

  // ---- Relational selection helpers ----

  /// Replaces the program and clears the stage, grade, and track ids, which
  /// all depend on it.
  RegistrationDraft withProgram(int programId) => copyWith(
    programId: programId,
    clearStageId: true,
    clearGradeId: true,
    clearTrackId: true,
    gradeNumber: null,
  );

  /// Replaces the stage and clears the grade and track ids.
  RegistrationDraft withStageId(int stageId) => copyWith(
    stageId: stageId,
    clearGradeId: true,
    clearTrackId: true,
    gradeNumber: null,
  );

  /// Replaces the grade and clears the track id.
  RegistrationDraft withGradeId(int gradeId, {int? gradeNumber}) => copyWith(
    gradeId: gradeId,
    gradeNumber: gradeNumber ?? this.gradeNumber,
    clearTrackId: true,
  );

  /// Replaces the track id. Passing null clears it.
  RegistrationDraft withTrackId(int? trackId) => trackId == null
      ? copyWith(clearTrackId: true)
      : copyWith(trackId: trackId);

  /// Replaces the governorate and clears the area id, which depends on it.
  RegistrationDraft withGovernorate(int governorateId) =>
      copyWith(governorateId: governorateId, clearAreaId: true);

  /// Replaces the area id. The governorate is unchanged.
  RegistrationDraft withArea(int areaId) => copyWith(areaId: areaId);
}

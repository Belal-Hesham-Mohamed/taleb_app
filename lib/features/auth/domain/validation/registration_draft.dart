import '../entities/education_path.dart';
import '../entities/registration_draft.dart';
import 'phone_number.dart';

/// Field level issues found by each registration step. A non-null field means
/// the field is invalid; the message key is chosen at presentation time.
class CredentialsIssues {
  const CredentialsIssues({
    this.phone,
    this.password,
    this.confirmPassword,
    this.email,
  });

  final String? phone;
  final String? password;
  final String? confirmPassword;
  final String? email;

  bool get isValid =>
      phone == null &&
      password == null &&
      confirmPassword == null &&
      email == null;
}

class PersonalIssues {
  const PersonalIssues({
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.studentId,
    this.guardianPhone,
    this.guardianId,
    this.governorate,
    this.area,
  });

  final String? fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? studentId;
  final String? guardianPhone;
  final String? guardianId;
  final String? governorate;
  final String? area;

  bool get isValid =>
      fullName == null &&
      dateOfBirth == null &&
      gender == null &&
      studentId == null &&
      guardianPhone == null &&
      guardianId == null &&
      governorate == null &&
      area == null;
}

class EducationIssues {
  const EducationIssues({
    this.stage,
    this.type,
    this.system,
    this.grade,
    this.track,
    this.school,
  });

  final String? stage;
  final String? type;
  final String? system;
  final String? grade;
  final String? track;
  final String? school;

  bool get isValid =>
      stage == null &&
      type == null &&
      system == null &&
      grade == null &&
      track == null &&
      school == null;
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

bool _isRealDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return false;
  final date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}

bool _isPastDate(int year, int month, int day) =>
    DateTime.utc(year, month, day).isBefore(DateTime.now().toUtc());

/// Validates the credentials step: required phone and password, a matching
/// confirmation, and an optional email that is only checked when provided.
CredentialsIssues credentialsIssues(RegistrationDraft draft) {
  final trimmedPhone = draft.phone.trim();
  final String? phoneIssue;
  if (trimmedPhone.isEmpty) {
    phoneIssue = 'phoneRequired';
  } else if (draft.normalizedPhone == null) {
    phoneIssue = 'phoneInvalid';
  } else {
    phoneIssue = null;
  }
  final password = draft.password.length < 8 ? 'passwordShort' : null;
  final confirmPassword = draft.confirmPassword != draft.password
      ? 'passwordMismatch'
      : null;
  final email =
      draft.email.trim().isNotEmpty &&
          !_emailPattern.hasMatch(draft.email.trim())
      ? 'emailInvalid'
      : null;
  return CredentialsIssues(
    phone: phoneIssue,
    password: password,
    confirmPassword: confirmPassword,
    email: email,
  );
}

/// Validates the personal-information step. Identity fields (student ID,
/// guardian identity) are optional; the remaining fields are required, and a
/// provided guardian phone is validated.
PersonalIssues personalIssues(RegistrationDraft draft) {
  String? validateDate(String value) {
    final match = _datePattern.firstMatch(value.trim());
    if (match == null) return 'dateOfBirthInvalid';
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (!_isRealDate(year, month, day) || !_isPastDate(year, month, day)) {
      return 'dateOfBirthInvalid';
    }
    return null;
  }

  return PersonalIssues(
    fullName: draft.fullName.trim().isEmpty ? 'fullNameRequired' : null,
    dateOfBirth: draft.dateOfBirth.trim().isEmpty
        ? 'dateOfBirthRequired'
        : validateDate(draft.dateOfBirth),
    gender: draft.gender == null ? 'genderRequired' : null,
    studentId: null,
    guardianPhone: draft.guardianPhone.trim().isEmpty
        ? 'guardianPhoneRequired'
        : (normalizePhoneNumber(draft.guardianPhone) == null
              ? 'guardianPhoneInvalid'
              : null),
    guardianId: null,
    governorate: draft.governorate.trim().isEmpty
        ? 'governorateRequired'
        : null,
    area: draft.area.trim().isEmpty ? 'areaRequired' : null,
  );
}

/// Validates the educational step against the configured academic rules.
EducationIssues educationIssues(RegistrationDraft draft) {
  final stage = draft.stage;
  final grade = draft.grade;
  if (stage == null) {
    return const EducationIssues(
      stage: 'stageRequired',
      grade: 'gradeRequired',
    );
  }
  if (grade == null || grade.stage != stage) {
    return EducationIssues(stage: null, grade: 'gradeInvalid');
  }

  final type = draft.type;
  final system = draft.system;
  final track = draft.track;

  if (stage != EducationalStage.secondary) {
    return EducationIssues(grade: track != null ? 'trackNotAllowed' : null);
  }

  if (type == null) {
    return const EducationIssues(type: 'educationTypeRequired');
  }
  final systems = academicSystemsForType(type);
  if (systems.isEmpty) {
    return EducationIssues(track: track != null ? 'trackNotAllowed' : null);
  }
  if (system == null) {
    return const EducationIssues(system: 'academicSystemRequired');
  }

  final allowedTracks = academicTracksFor(system, grade);
  final String? trackIssue;
  if (allowedTracks == null) {
    trackIssue = track != null ? 'trackNotAllowed' : null;
  } else {
    trackIssue = track != null && allowedTracks.contains(track)
        ? null
        : 'trackInvalid';
  }
  return EducationIssues(track: trackIssue);
}

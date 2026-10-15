import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/features/auth/domain/entities/education_path.dart';
import 'package:taleb/features/auth/domain/entities/registration_draft.dart';
import 'package:taleb/features/auth/domain/validation/registration_draft.dart';

RegistrationDraft _draft({
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
}) => RegistrationDraft(
  phone: phone ?? '',
  password: password ?? '',
  confirmPassword: confirmPassword ?? '',
  email: email ?? '',
  fullName: fullName ?? '',
  dateOfBirth: dateOfBirth ?? '',
  gender: gender,
  studentId: studentId ?? '',
  guardianPhone: guardianPhone ?? '',
  guardianId: guardianId ?? '',
  governorate: governorate ?? '',
  area: area ?? '',
  stage: stage,
  type: type,
  system: system,
  grade: grade,
  track: track,
  school: school ?? '',
);

void main() {
  group('credentials step', () {
    test('requires a phone number', () {
      final result = credentialsIssues(_draft(password: 'secret123'));
      expect(result.phone, 'phoneRequired');
    });

    test('rejects a phone number that is not a valid Egyptian mobile', () {
      final result = credentialsIssues(
        _draft(phone: '12345', password: 'secret123'),
      );
      expect(result.phone, 'phoneInvalid');
    });

    test('accepts a normalized Egyptian mobile number', () {
      final result = credentialsIssues(
        _draft(phone: '01234567890', password: 'secret123'),
      );
      expect(result.phone, isNull);
    });

    test('requires a password of at least eight characters', () {
      expect(
        credentialsIssues(
          _draft(phone: '01234567890', password: 'short'),
        ).password,
        isNotNull,
      );
      expect(
        credentialsIssues(
          _draft(phone: '01234567890', password: '12345678'),
        ).password,
        isNull,
      );
    });

    test('requires the confirmation to match the password', () {
      final result = credentialsIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          confirmPassword: 'secret124',
        ),
      );
      expect(result.confirmPassword, isNotNull);
      expect(
        credentialsIssues(
          _draft(
            phone: '01234567890',
            password: 'secret123',
            confirmPassword: 'secret123',
          ),
        ).confirmPassword,
        isNull,
      );
    });

    test('allows an empty email but rejects a malformed one', () {
      expect(
        credentialsIssues(
          _draft(phone: '01234567890', password: 'secret123'),
        ).email,
        isNull,
      );
      expect(
        credentialsIssues(
          _draft(
            phone: '01234567890',
            password: 'secret123',
            email: 'not-an-email',
          ),
        ).email,
        isNotNull,
      );
      expect(
        credentialsIssues(
          _draft(phone: '01234567890', password: 'secret123', email: 'a@b.co'),
        ).email,
        isNull,
      );
    });
  });

  group('personal step', () {
    test('requires name, birth date, gender, and location', () {
      final result = personalIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          guardianPhone: '01234567891',
        ),
      );
      expect(result.fullName, isNotNull);
      expect(result.dateOfBirth, isNotNull);
      expect(result.gender, isNotNull);
      expect(result.governorate, isNotNull);
      expect(result.area, isNotNull);
    });

    test('accepts a complete personal step', () {
      final result = personalIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          fullName: 'أحمد محمد علي حسن',
          dateOfBirth: '2007-01-15',
          gender: Gender.male,
          guardianPhone: '01234567891',
          guardianId: '29901011234567',
          governorate: 'cairo',
          area: 'nasr_city',
        ),
      );
      expect(result.isValid, isTrue);
    });

    test('treats student and guardian identity as optional', () {
      final result = personalIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          fullName: 'Ahmed',
          dateOfBirth: '2007-01-15',
          gender: Gender.male,
          governorate: 'cairo',
          area: 'nasr_city',
        ),
      );
      expect(result.studentId, isNull);
      expect(result.guardianId, isNull);
    });

    test('rejects an invalid guardian phone number when one is provided', () {
      final result = personalIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          fullName: 'Ahmed',
          dateOfBirth: '2007-01-15',
          gender: Gender.male,
          guardianPhone: '123',
          governorate: 'cairo',
          area: 'nasr_city',
        ),
      );
      expect(result.guardianPhone, isNotNull);
    });

    test(
      'rejects a birth date that is not a real date or is in the future',
      () {
        final base = _draft(
          phone: '01234567890',
          password: 'secret123',
          fullName: 'Ahmed',
          gender: Gender.male,
          guardianPhone: '01234567891',
          governorate: 'cairo',
          area: 'nasr_city',
        );
        expect(
          personalIssues(base.copyWith(dateOfBirth: 'not-a-date')).dateOfBirth,
          isNotNull,
        );
        expect(
          personalIssues(base.copyWith(dateOfBirth: '2999-01-01')).dateOfBirth,
          isNotNull,
        );
      },
    );
  });

  group('education step', () {
    test('requires a stage and a grade', () {
      final result = educationIssues(
        _draft(phone: '01234567890', password: 'secret123'),
      );
      expect(result.stage, isNotNull);
      expect(result.grade, isNotNull);
    });

    test(
      'primary and preparatory need neither a type nor a system nor a track',
      () {
        final result = educationIssues(
          _draft(
            phone: '01234567890',
            password: 'secret123',
            stage: EducationalStage.preparatory,
            grade: StudyGrade.preparatory2,
          ),
        );
        expect(result.isValid, isTrue);
      },
    );

    test('secondary general requires a system', () {
      final result = educationIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          stage: EducationalStage.secondary,
          type: EducationType.general,
          grade: StudyGrade.secondary1,
        ),
      );
      expect(result.system, isNotNull);
    });

    test('secondary Azhar, technical, and international need no system', () {
      for (final type in [
        EducationType.azhari,
        EducationType.technical,
        EducationType.international,
      ]) {
        final result = educationIssues(
          _draft(
            phone: '01234567890',
            password: 'secret123',
            stage: EducationalStage.secondary,
            type: type,
            grade: StudyGrade.secondary2,
          ),
        );
        expect(result.isValid, isTrue, reason: '$type');
      }
    });

    test('the grade must belong to the selected stage', () {
      final result = educationIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          stage: EducationalStage.primary,
          grade: StudyGrade.secondary3,
        ),
      );
      expect(result.grade, isNotNull);
    });

    test('a required track must be present and valid', () {
      final missing = educationIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          stage: EducationalStage.secondary,
          type: EducationType.general,
          system: AcademicSystem.generalSecondary,
          grade: StudyGrade.secondary2,
        ),
      );
      expect(missing.track, isNotNull);

      final invalid = educationIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          stage: EducationalStage.secondary,
          type: EducationType.general,
          system: AcademicSystem.generalSecondary,
          grade: StudyGrade.secondary2,
          track: AcademicTrack.mathematics,
        ),
      );
      expect(invalid.track, isNotNull);

      final valid = educationIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          stage: EducationalStage.secondary,
          type: EducationType.general,
          system: AcademicSystem.generalSecondary,
          grade: StudyGrade.secondary2,
          track: AcademicTrack.scientific,
        ),
      );
      expect(valid.track, isNull);
      expect(valid.isValid, isTrue);
    });

    test('no track is required when the path does not need one', () {
      final result = educationIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          stage: EducationalStage.secondary,
          type: EducationType.general,
          system: AcademicSystem.egyptianBaccalaureate,
          grade: StudyGrade.secondary1,
        ),
      );
      expect(result.track, isNull);
      expect(result.isValid, isTrue);
    });

    test('a leftover track from another path is reported', () {
      final result = educationIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          stage: EducationalStage.secondary,
          type: EducationType.general,
          system: AcademicSystem.egyptianBaccalaureate,
          grade: StudyGrade.secondary1,
          track: AcademicTrack.scientific,
        ),
      );
      expect(result.track, isNotNull);
    });

    test('school stays optional', () {
      final result = educationIssues(
        _draft(
          phone: '01234567890',
          password: 'secret123',
          stage: EducationalStage.primary,
          grade: StudyGrade.primary4,
        ),
      );
      expect(result.school, isNull);
    });
  });

  group('dependent selection changes', () {
    test('changing the stage clears the type, system, grade, and track', () {
      final draft = _draft(
        phone: '01234567890',
        password: 'secret123',
        stage: EducationalStage.secondary,
        type: EducationType.general,
        system: AcademicSystem.generalSecondary,
        grade: StudyGrade.secondary2,
        track: AcademicTrack.scientific,
      ).withStage(EducationalStage.primary);
      expect(draft.type, isNull);
      expect(draft.system, isNull);
      expect(draft.grade, isNull);
      expect(draft.track, isNull);
    });

    test('changing the education type clears the system and track', () {
      final draft = _draft(
        phone: '01234567890',
        password: 'secret123',
        stage: EducationalStage.secondary,
        type: EducationType.general,
        system: AcademicSystem.generalSecondary,
        grade: StudyGrade.secondary2,
        track: AcademicTrack.scientific,
      ).withType(EducationType.azhari);
      expect(draft.system, isNull);
      expect(draft.track, isNull);
      expect(draft.grade, StudyGrade.secondary2);
    });

    test('changing the system clears the track and keeps the grade', () {
      final draft = _draft(
        phone: '01234567890',
        password: 'secret123',
        stage: EducationalStage.secondary,
        type: EducationType.general,
        system: AcademicSystem.generalSecondary,
        grade: StudyGrade.secondary2,
        track: AcademicTrack.scientific,
      ).withSystem(AcademicSystem.egyptianBaccalaureate);
      expect(draft.track, isNull);
      expect(draft.grade, StudyGrade.secondary2);
    });

    test('changing the grade clears a track that is no longer valid', () {
      final draft = _draft(
        phone: '01234567890',
        password: 'secret123',
        stage: EducationalStage.secondary,
        type: EducationType.general,
        system: AcademicSystem.egyptianBaccalaureate,
        grade: StudyGrade.secondary2,
        track: AcademicTrack.businessStudies,
      ).withGrade(StudyGrade.secondary1);
      expect(draft.track, isNull);
    });

    test('a valid selection survives an unchanged system', () {
      final draft = _draft(
        phone: '01234567890',
        password: 'secret123',
        stage: EducationalStage.secondary,
        type: EducationType.general,
        system: AcademicSystem.generalSecondary,
        grade: StudyGrade.secondary2,
        track: AcademicTrack.scientific,
      ).withSystem(AcademicSystem.generalSecondary);
      expect(draft.track, isNull);
    });
  });
}

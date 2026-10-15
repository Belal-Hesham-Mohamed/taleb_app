import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/features/auth/domain/entities/catalog.dart';
import 'package:taleb/features/auth/domain/entities/education_path.dart';
import 'package:taleb/features/auth/domain/entities/registration_draft.dart';

void main() {
  RegistrationDraft draft() => const RegistrationDraft.empty();

  group('location selection', () {
    test('stores the governorate and area ids', () {
      final updated = draft().copyWith(governorateId: 1, areaId: 100);
      expect(updated.governorateId, 1);
      expect(updated.areaId, 100);
    });

    test('changing the governorate clears the area id', () {
      final updated = draft()
          .copyWith(governorateId: 1, areaId: 100)
          .withGovernorate(2);
      expect(updated.governorateId, 2);
      expect(updated.areaId, isNull);
    });

    test('selecting an area keeps the governorate', () {
      final updated = draft().copyWith(governorateId: 1).withArea(100);
      expect(updated.governorateId, 1);
      expect(updated.areaId, 100);
    });

    test('the localized labels come from the catalog, not the draft', () {
      final governorate = CatalogOption.fromMap({
        'id': 1,
        'code': 'cairo',
        'name_ar': 'القاهرة',
        'name_en': 'Cairo',
      });
      final area = AreaOption.fromMap({
        'id': 100,
        'governorate_id': 1,
        'code': 'nasr_city',
        'name_ar': 'مدينة نصر',
        'name_en': 'Nasr City',
        'area_type': 'city',
      });
      final updated = draft().copyWith(
        governorateId: governorate.id,
        areaId: area.id,
      );
      // The draft stores only ids; labels are resolved from the catalog.
      expect(updated.governorateId, 1);
      expect(updated.areaId, 100);
      expect(governorate.label('ar'), 'القاهرة');
      expect(area.label('en'), 'Nasr City');
    });
  });

  group('education selection', () {
    test('stores the program, stage, grade, and track ids', () {
      final updated = draft().copyWith(
        programId: 1,
        stageId: 2,
        gradeId: 3,
        trackId: 4,
      );
      expect(updated.programId, 1);
      expect(updated.stageId, 2);
      expect(updated.gradeId, 3);
      expect(updated.trackId, 4);
    });

    test('changing the program clears the stage, grade, and track', () {
      final updated = draft()
          .copyWith(programId: 1, stageId: 2, gradeId: 3, trackId: 4)
          .withProgram(5);
      expect(updated.programId, 5);
      expect(updated.stageId, isNull);
      expect(updated.gradeId, isNull);
      expect(updated.trackId, isNull);
    });

    test('changing the stage clears the grade and track', () {
      final updated = draft()
          .copyWith(programId: 1, stageId: 2, gradeId: 3, trackId: 4)
          .withStageId(6);
      expect(updated.stageId, 6);
      expect(updated.gradeId, isNull);
      expect(updated.trackId, isNull);
    });

    test('changing the grade clears the track', () {
      final updated = draft()
          .copyWith(programId: 1, stageId: 2, gradeId: 3, trackId: 4)
          .withGradeId(7);
      expect(updated.gradeId, 7);
      expect(updated.trackId, isNull);
    });

    test('the grade number is kept for track applicability', () {
      final updated = draft().copyWith(gradeId: 3, gradeNumber: 2);
      expect(updated.gradeNumber, 2);
    });
  });

  group('school', () {
    test('school name is optional and empty by default', () {
      expect(draft().schoolName, '');
    });

    test('school type is stored when provided', () {
      final updated = draft().copyWith(schoolType: 'public');
      expect(updated.schoolType, 'public');
    });
  });

  group('persistence payload', () {
    test('serializes the verified student_profiles columns', () {
      final updated = draft().copyWith(
        programId: 1,
        stageId: 2,
        gradeId: 3,
        trackId: 4,
        governorateId: 5,
        areaId: 100,
        schoolName: 'Nile School',
        schoolType: 'public',
      );
      final payload = updated.toProfilePayload();
      expect(payload['education_program_id'], 1);
      expect(payload['education_grade_id'], 3);
      expect(payload['education_track_id'], 4);
      expect(payload['area_id'], 100);
      expect(payload['school_name'], 'Nile School');
      expect(payload['school_type'], 'public');
    });

    test('omits null foreign keys instead of writing empty strings', () {
      final payload = draft().toProfilePayload();
      expect(payload.containsKey('education_program_id'), isFalse);
      expect(payload.containsKey('education_track_id'), isFalse);
      expect(payload.containsKey('area_id'), isFalse);
    });

    test('omits an empty school name so it stays optional', () {
      final payload = draft().toProfilePayload();
      expect(payload.containsKey('school_name'), isFalse);
      expect(payload.containsKey('school_type'), isFalse);
    });

    test('keeps the legacy text fields for backward compatibility', () {
      final updated = draft().copyWith(
        governorate: 'cairo',
        area: 'nasr_city',
        stage: EducationalStage.secondary,
      );
      final payload = updated.toProfilePayload();
      expect(payload['governorate'], 'cairo');
      expect(payload['area'], 'nasr_city');
      expect(payload['education_stage'], 'secondary');
    });

    test('never contains the password', () {
      final updated = draft().copyWith(password: 'secret123');
      final payload = updated.toProfilePayload();
      expect(payload.values.any((v) => v == 'secret123'), isFalse);
      expect(payload.containsKey('password'), isFalse);
    });
  });
}

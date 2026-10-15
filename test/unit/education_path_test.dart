import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/features/auth/domain/entities/education_path.dart';

void main() {
  group('gradesForStage', () {
    test('primary offers six grades', () {
      expect(gradesForStage(EducationalStage.primary), hasLength(6));
      expect(
        gradesForStage(EducationalStage.primary).first,
        StudyGrade.primary1,
      );
      expect(
        gradesForStage(EducationalStage.primary).last,
        StudyGrade.primary6,
      );
    });

    test('preparatory offers three grades', () {
      expect(gradesForStage(EducationalStage.preparatory), hasLength(3));
      expect(
        gradesForStage(EducationalStage.preparatory).first,
        StudyGrade.preparatory1,
      );
    });

    test('secondary offers three grades', () {
      expect(gradesForStage(EducationalStage.secondary), hasLength(3));
      expect(
        gradesForStage(EducationalStage.secondary).first,
        StudyGrade.secondary1,
      );
    });

    test('every grade belongs to its stage', () {
      for (final stage in EducationalStage.values) {
        for (final grade in gradesForStage(stage)) {
          expect(grade.stage, stage);
        }
      }
    });
  });

  group('educationTypesForStage', () {
    test('only the secondary stage has education types', () {
      expect(educationTypesForStage(EducationalStage.primary), isEmpty);
      expect(educationTypesForStage(EducationalStage.preparatory), isEmpty);
      expect(
        educationTypesForStage(EducationalStage.secondary),
        EducationType.values,
      );
    });
  });

  group('academicSystemsForType', () {
    test('only general secondary education has configured systems', () {
      expect(academicSystemsForType(EducationType.general), [
        AcademicSystem.egyptianBaccalaureate,
        AcademicSystem.generalSecondary,
      ]);
      for (final type in EducationType.values.where(
        (type) => type != EducationType.general,
      )) {
        expect(academicSystemsForType(type), isEmpty);
      }
    });
  });

  group('academicTracksFor', () {
    test('the Egyptian Baccalaureate first year needs no track', () {
      expect(
        academicTracksFor(
          AcademicSystem.egyptianBaccalaureate,
          StudyGrade.secondary1,
        ),
        isNull,
      );
      expect(
        requiresAcademicTrack(
          AcademicSystem.egyptianBaccalaureate,
          StudyGrade.secondary1,
        ),
        isFalse,
      );
    });

    test(
      'the Egyptian Baccalaureate second and third years offer four tracks',
      () {
        const expected = [
          AcademicTrack.medicineAndLifeSciences,
          AcademicTrack.engineeringAndComputerScience,
          AcademicTrack.businessStudies,
          AcademicTrack.artsAndLiterature,
        ];
        for (final grade in [StudyGrade.secondary2, StudyGrade.secondary3]) {
          expect(
            academicTracksFor(AcademicSystem.egyptianBaccalaureate, grade),
            expected,
          );
          expect(
            requiresAcademicTrack(AcademicSystem.egyptianBaccalaureate, grade),
            isTrue,
          );
        }
      },
    );

    test('general secondary splits scientific and literary in year two', () {
      expect(
        academicTracksFor(
          AcademicSystem.generalSecondary,
          StudyGrade.secondary2,
        ),
        [AcademicTrack.scientific, AcademicTrack.literary],
      );
      expect(
        academicTracksFor(
          AcademicSystem.generalSecondary,
          StudyGrade.secondary1,
        ),
        isNull,
      );
    });

    test(
      'general secondary year three offers sciences, mathematics, literary',
      () {
        expect(
          academicTracksFor(
            AcademicSystem.generalSecondary,
            StudyGrade.secondary3,
          ),
          [
            AcademicTrack.sciences,
            AcademicTrack.mathematics,
            AcademicTrack.literary,
          ],
        );
      },
    );

    test('a grade outside the secondary stage never needs a track', () {
      expect(
        academicTracksFor(
          AcademicSystem.egyptianBaccalaureate,
          StudyGrade.primary4,
        ),
        isNull,
      );
    });
  });

  group('isValidAcademicTrack', () {
    test('accepts a configured track for the selected path', () {
      expect(
        isValidAcademicTrack(
          AcademicTrack.scientific,
          AcademicSystem.generalSecondary,
          StudyGrade.secondary2,
        ),
        isTrue,
      );
    });

    test('rejects a track that the selected path does not offer', () {
      expect(
        isValidAcademicTrack(
          AcademicTrack.mathematics,
          AcademicSystem.generalSecondary,
          StudyGrade.secondary2,
        ),
        isFalse,
      );
      expect(
        isValidAcademicTrack(
          AcademicTrack.scientific,
          AcademicSystem.egyptianBaccalaureate,
          StudyGrade.secondary2,
        ),
        isFalse,
      );
    });

    test('rejects every track when no track is required', () {
      for (final track in AcademicTrack.values) {
        expect(
          isValidAcademicTrack(
            track,
            AcademicSystem.egyptianBaccalaureate,
            StudyGrade.secondary1,
          ),
          isFalse,
        );
      }
    });
  });
}

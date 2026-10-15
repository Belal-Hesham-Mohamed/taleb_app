import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/features/auth/domain/entities/catalog.dart';

Map<String, dynamic> _program({
  Object? id = 1,
  String? code = 'general',
  String nameAr = 'عام',
  String nameEn = 'General',
}) => {'id': id, 'code': code, 'name_ar': nameAr, 'name_en': nameEn};

Map<String, dynamic> _subject({
  Object? id = 10,
  String code = 'arabic',
  bool isActive = true,
}) => {
  'id': id,
  'code': code,
  'name_ar': 'اللغة العربية',
  'name_en': 'Arabic',
  'is_active': isActive,
};

void main() {
  group('id parsing', () {
    test('accepts int, string, and num ids', () {
      expect(asInt(7), 7);
      expect(asInt('7'), 7);
      expect(asInt(7.0), 7);
    });

    test('rejects anything else instead of coercing silently', () {
      expect(() => asInt(null), throwsFormatException);
      expect(() => asInt('abc'), throwsA(isA<Exception>()));
    });
  });

  group('CatalogOption', () {
    test('parses the verified columns', () {
      final option = CatalogOption.fromMap(_program());
      expect(option.id, 1);
      expect(option.code, 'general');
      expect(option.nameAr, 'عام');
      expect(option.nameEn, 'General');
    });

    test('parses a string id from a bigint column', () {
      final option = CatalogOption.fromMap(_program(id: '42'));
      expect(option.id, 42);
    });

    test('localizes the label from the catalog row', () {
      final option = CatalogOption.fromMap(_program());
      expect(option.label('ar'), 'عام');
      expect(option.label('en'), 'General');
      // An unknown language falls back to English rather than a raw id.
      expect(option.label('fr'), 'General');
    });
  });

  group('GradeOption', () {
    test('parses the numeric grade number', () {
      final grade = GradeOption.fromMap({
        'id': 5,
        'name_ar': 'الصف الأول',
        'name_en': 'Grade 1',
        'grade_number': 1,
      });
      expect(grade.id, 5);
      expect(grade.gradeNumber, 1);
      expect(grade.label('en'), 'Grade 1');
    });

    test('parses a string grade number', () {
      final grade = GradeOption.fromMap({
        'id': 5,
        'name_ar': 'الصف الثالث',
        'name_en': 'Grade 3',
        'grade_number': '3',
      });
      expect(grade.gradeNumber, 3);
    });
  });

  group('TrackOption', () {
    test('applies when the grade is inside both boundaries', () {
      final track = TrackOption.fromMap({
        'id': 2,
        'code': 'general_science',
        'name_ar': 'علمي',
        'name_en': 'Science',
        'min_grade_number': 2,
        'max_grade_number': 3,
      });
      expect(track.appliesToGrade(1), isFalse);
      expect(track.appliesToGrade(2), isTrue);
      expect(track.appliesToGrade(3), isTrue);
      expect(track.appliesToGrade(4), isFalse);
    });

    test('a null boundary means unbounded on that side', () {
      final track = TrackOption.fromMap({
        'id': 2,
        'code': 'x',
        'name_ar': 'أ',
        'name_en': 'X',
        'min_grade_number': null,
        'max_grade_number': 1,
      });
      expect(track.appliesToGrade(1), isTrue);
      expect(track.appliesToGrade(2), isFalse);

      final open = TrackOption.fromMap({
        'id': 3,
        'code': 'y',
        'name_ar': 'ب',
        'name_en': 'Y',
        'min_grade_number': null,
        'max_grade_number': null,
      });
      expect(open.appliesToGrade(1), isTrue);
      expect(open.appliesToGrade(9), isTrue);
    });

    test('parses string boundaries', () {
      final track = TrackOption.fromMap({
        'id': 2,
        'code': 'x',
        'name_ar': 'أ',
        'name_en': 'X',
        'min_grade_number': '2',
        'max_grade_number': '3',
      });
      expect(track.minGradeNumber, 2);
      expect(track.maxGradeNumber, 3);
    });
  });

  group('AreaOption', () {
    test('parses the governorate link and area type', () {
      final area = AreaOption.fromMap({
        'id': 100,
        'governorate_id': '1',
        'code': 'nasr_city',
        'name_ar': 'مدينة نصر',
        'name_en': 'Nasr City',
        'area_type': 'city',
      });
      expect(area.governorateId, 1);
      expect(area.areaType, 'city');
      expect(area.label('ar'), 'مدينة نصر');
    });
  });

  group('GradeSubjectOption', () {
    test('parses a row with an active embedded subject', () {
      final row = GradeSubjectOption.fromMap({
        'is_required': true,
        'counts_toward_total': true,
        'education_subjects': _subject(),
      });
      expect(row, isNotNull);
      expect(row!.subject.label('en'), 'Arabic');
      expect(row.isRequired, isTrue);
      expect(row.countsTowardTotal, isTrue);
    });

    test('drops a row whose subject is inactive', () {
      final row = GradeSubjectOption.fromMap({
        'is_required': true,
        'counts_toward_total': true,
        'education_subjects': _subject(isActive: false),
      });
      expect(row, isNull);
    });

    test('drops a row whose embedded subject is missing', () {
      final row = GradeSubjectOption.fromMap({
        'is_required': true,
        'counts_toward_total': true,
        'education_subjects': null,
      });
      expect(row, isNull);
    });

    test('defaults missing flags to false', () {
      final row = GradeSubjectOption.fromMap({
        'education_subjects': _subject(),
      })!;
      expect(row.isRequired, isFalse);
      expect(row.countsTowardTotal, isFalse);
    });
  });

  group('TrackSubjectOption', () {
    test('parses role and choice group', () {
      final row = TrackSubjectOption.fromMap({
        'subject_role': 'choice',
        'choice_group': 'lang',
        'is_advanced': true,
        'is_required': false,
        'counts_toward_total': true,
        'education_subjects': _subject(),
      })!;
      expect(row.isChoice, isTrue);
      expect(row.choiceGroup, 'lang');
      expect(row.isAdvanced, isTrue);
    });

    test('a required subject is not a choice', () {
      final row = TrackSubjectOption.fromMap({
        'subject_role': 'required',
        'choice_group': null,
        'is_advanced': false,
        'is_required': true,
        'counts_toward_total': true,
        'education_subjects': _subject(),
      })!;
      expect(row.isChoice, isFalse);
      expect(row.choiceGroup, isNull);
    });

    test('drops a row whose subject is inactive', () {
      final row = TrackSubjectOption.fromMap({
        'subject_role': 'required',
        'education_subjects': _subject(isActive: false),
      });
      expect(row, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/features/auth/data/datasources/catalog_client.dart';
import 'package:taleb/features/auth/data/datasources/supabase_catalog_datasource.dart';

class _FakeCatalogClient implements CatalogClient {
  _FakeCatalogClient(this.rows);

  /// Rows keyed by table name.
  final Map<String, List<CatalogRow>> rows;

  /// Records every call so tests can assert the query contract.
  final List<Map<String, Object?>> calls = [];

  /// When set, the next call throws this instead of returning rows.
  Object? error;

  @override
  Future<List<CatalogRow>> select({
    required String table,
    List<CatalogFilter> filters = const [],
    String? orderColumn,
    bool ascending = true,
  }) async {
    calls.add({
      'kind': 'select',
      'table': table,
      'filters': filters.map((f) => '${f.column}=${f.value}').toList(),
      'orderColumn': orderColumn,
    });
    if (error != null) throw error!;
    return rows[table] ?? const [];
  }

  @override
  Future<List<CatalogRow>> selectTracks({
    required String table,
    required List<CatalogFilter> filters,
    required int gradeNumber,
  }) async {
    calls.add({
      'kind': 'tracks',
      'table': table,
      'filters': filters.map((f) => '${f.column}=${f.value}').toList(),
      'gradeNumber': gradeNumber,
    });
    if (error != null) throw error!;
    return rows[table] ?? const [];
  }
}

CatalogRow _program(Object id, {String code = 'general'}) => {
  'id': id,
  'code': code,
  'name_ar': 'عام',
  'name_en': 'General',
  'is_active': true,
};

CatalogRow _stage(Object id, {String code = 'secondary'}) => {
  'id': id,
  'code': code,
  'name_ar': 'ثانوي',
  'name_en': 'Secondary',
};

CatalogRow _grade(Object id, int number) => {
  'id': id,
  'program_id': 1,
  'stage_id': 2,
  'grade_number': number,
  'name_ar': 'الصف $number',
  'name_en': 'Grade $number',
  'is_active': true,
};

CatalogRow _track(Object id, {int? min, int? max}) => {
  'id': id,
  'program_id': 1,
  'stage_id': 2,
  'code': 't$id',
  'name_ar': 'مسار $id',
  'name_en': 'Track $id',
  'min_grade_number': min,
  'max_grade_number': max,
  'is_active': true,
};

CatalogRow _subject(Object id, {bool isActive = true}) => {
  'id': id,
  'code': 's$id',
  'name_ar': 'مادة $id',
  'name_en': 'Subject $id',
  'is_active': isActive,
};

void main() {
  late _FakeCatalogClient client;
  late SupabaseCatalogDatasource datasource;

  setUp(() {
    client = _FakeCatalogClient({});
    datasource = SupabaseCatalogDatasource(client);
  });

  group('programs', () {
    test('reads the education_programs table', () async {
      client.rows['education_programs'] = [_program(1)];
      final result = await datasource.loadPrograms();
      expect(result.single.id, 1);
      expect(client.calls.single['table'], 'education_programs');
      expect(client.calls.single['orderColumn'], 'sort_order');
    });

    test('filters active programs', () async {
      client.rows['education_programs'] = [_program(1)];
      await datasource.loadPrograms();
      expect(
        (client.calls.single['filters'] as List).contains('is_active=true'),
        isTrue,
      );
    });
  });

  group('stages', () {
    test('reads education_stages without an is_active filter', () async {
      client.rows['education_stages'] = [_stage(2)];
      final result = await datasource.loadStages();
      expect(result.single.id, 2);
      expect(
        (client.calls.single['filters'] as List),
        isEmpty,
        reason: 'education_stages has no is_active column',
      );
      expect(client.calls.single['orderColumn'], 'sort_order');
    });
  });

  group('grades', () {
    test('filters by both program and stage id', () async {
      client.rows['education_grades'] = [_grade(3, 1)];
      final result = await datasource.loadGrades(programId: 1, stageId: 2);
      expect(result.single.gradeNumber, 1);
      final filters = client.calls.single['filters'] as List;
      expect(filters, containsAll(['program_id=1', 'stage_id=2']));
      expect(filters, contains('is_active=true'));
      expect(client.calls.single['orderColumn'], 'grade_number');
    });

    test('never returns a grade from another program or stage', () async {
      // The database filters; the datasource simply maps what it is given.
      client.rows['education_grades'] = [
        _grade(3, 1),
        _grade(4, 2),
        _grade(5, 3),
      ];
      final result = await datasource.loadGrades(programId: 1, stageId: 2);
      expect(result.map((g) => g.gradeNumber), [1, 2, 3]);
    });
  });

  group('tracks', () {
    test('applies the grade range and filters active tracks', () async {
      client.rows['education_tracks'] = [_track(7, min: 2, max: 3)];
      final result = await datasource.loadTracks(
        programId: 1,
        stageId: 2,
        gradeNumber: 2,
      );
      expect(result.single.id, 7);
      expect(client.calls.single['kind'], 'tracks');
      expect(client.calls.single['gradeNumber'], 2);
      final filters = client.calls.single['filters'] as List;
      expect(filters, containsAll(['program_id=1', 'stage_id=2']));
      expect(filters, contains('is_active=true'));
    });

    test('parses nullable range boundaries', () async {
      client.rows['education_tracks'] = [_track(7, min: null, max: null)];
      final result = await datasource.loadTracks(
        programId: 1,
        stageId: 2,
        gradeNumber: 9,
      );
      expect(result.single.appliesToGrade(9), isTrue);
    });
  });

  group('grade subjects', () {
    test('embeds the subject catalog and filters grade', () async {
      client.rows['education_grade_subjects'] = [
        {
          'is_required': true,
          'counts_toward_total': true,
          'education_subjects': _subject(20),
        },
      ];
      final result = await datasource.loadGradeSubjects(gradeId: 3);
      expect(result.single.subject.label('en'), 'Subject 20');
      expect(result.single.isRequired, isTrue);
      final filters = client.calls.single['filters'] as List;
      expect(filters, contains('grade_id=3'));
    });

    test('drops rows whose subject is inactive', () async {
      client.rows['education_grade_subjects'] = [
        {
          'is_required': true,
          'counts_toward_total': true,
          'education_subjects': _subject(20, isActive: false),
        },
      ];
      final result = await datasource.loadGradeSubjects(gradeId: 3);
      expect(result, isEmpty);
    });
  });

  group('track subjects', () {
    test('filters by both track and grade', () async {
      client.rows['education_track_subjects'] = [
        {
          'subject_role': 'choice',
          'choice_group': 'lang',
          'is_advanced': true,
          'is_required': false,
          'counts_toward_total': true,
          'education_subjects': _subject(30),
        },
      ];
      final result = await datasource.loadTrackSubjects(trackId: 7, gradeId: 8);
      expect(result.single.isChoice, isTrue);
      expect(result.single.choiceGroup, 'lang');
      final filters = client.calls.single['filters'] as List;
      expect(filters, containsAll(['track_id=7', 'grade_id=8']));
    });
  });

  group('governorates', () {
    test('reads active governorates', () async {
      client.rows['governorates'] = [
        {
          'id': 1,
          'code': 'cairo',
          'name_ar': 'القاهرة',
          'name_en': 'Cairo',
          'is_active': true,
        },
      ];
      final result = await datasource.loadGovernorates();
      expect(result.single.label('ar'), 'القاهرة');
      expect(client.calls.single['table'], 'governorates');
    });
  });

  group('areas', () {
    test('filters by the selected governorate id', () async {
      client.rows['areas'] = [
        {
          'id': 100,
          'governorate_id': 1,
          'code': 'nasr_city',
          'name_ar': 'مدينة نصر',
          'name_en': 'Nasr City',
          'area_type': 'city',
        },
      ];
      final result = await datasource.loadAreas(governorateId: 1);
      expect(result.single.areaType, 'city');
      final filters = client.calls.single['filters'] as List;
      expect(filters, contains('governorate_id=1'));
      expect(filters, contains('is_active=true'));
    });
  });

  group('empty results', () {
    test('every catalog call returns an empty list, never null', () async {
      expect(await datasource.loadPrograms(), isEmpty);
      expect(await datasource.loadStages(), isEmpty);
      expect(await datasource.loadGrades(programId: 1, stageId: 2), isEmpty);
      expect(
        await datasource.loadTracks(programId: 1, stageId: 2, gradeNumber: 1),
        isEmpty,
      );
      expect(await datasource.loadGradeSubjects(gradeId: 1), isEmpty);
      expect(
        await datasource.loadTrackSubjects(trackId: 1, gradeId: 2),
        isEmpty,
      );
      expect(await datasource.loadGovernorates(), isEmpty);
      expect(await datasource.loadAreas(governorateId: 1), isEmpty);
    });
  });

  group('errors', () {
    test('a database error propagates to the caller', () async {
      client.error = Exception('db down');
      expect(() => datasource.loadPrograms(), throwsA(isA<Exception>()));
    });
  });
}

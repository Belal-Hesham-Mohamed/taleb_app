import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/features/auth/domain/entities/catalog.dart';
import 'package:taleb/features/auth/domain/repositories/registration_repository.dart';
import 'package:taleb/features/auth/presentation/cubit/registration_cubit.dart';

/// A catalog repository with controllable latency, so tests can exercise
/// race handling by delaying a request and completing a newer one first.
class _FakeCatalog implements CatalogRepository {
  _FakeCatalog();

  List<CatalogOption> programs = [];
  List<CatalogOption> stages = [];
  List<GradeOption> grades = [];
  List<TrackOption> tracks = [];
  List<CatalogOption> governorates = [];
  List<AreaOption> areas = [];
  Duration latency = Duration.zero;

  /// Gates per call kind, so a test can hold a request open.
  final Map<String, Completer<void>> gates = {};

  int gradeCalls = 0;
  int trackCalls = 0;
  int areaCalls = 0;

  /// Records the arguments of every call.
  final List<String> callLog = [];

  void setGate(String kind) => gates[kind] = Completer<void>();

  @override
  Future<List<CatalogOption>> loadPrograms() async {
    callLog.add('programs');
    await _delay();
    return programs;
  }

  @override
  Future<List<CatalogOption>> loadStages() async {
    callLog.add('stages');
    await _delay();
    return stages;
  }

  @override
  Future<List<GradeOption>> loadGrades({
    required int programId,
    required int stageId,
  }) async {
    gradeCalls++;
    callLog.add('grades:$programId:$stageId');
    await _delay();
    return grades;
  }

  @override
  Future<List<TrackOption>> loadTracks({
    required int programId,
    required int stageId,
    required int gradeNumber,
  }) async {
    trackCalls++;
    callLog.add('tracks:$programId:$stageId:$gradeNumber');
    await _delay();
    return tracks;
  }

  @override
  Future<List<GradeSubjectOption>> loadGradeSubjects({
    required int gradeId,
  }) async {
    callLog.add('gradeSubjects:$gradeId');
    await _delay();
    return const [];
  }

  @override
  Future<List<TrackSubjectOption>> loadTrackSubjects({
    required int trackId,
    required int gradeId,
  }) async {
    callLog.add('trackSubjects:$trackId:$gradeId');
    await _delay();
    return const [];
  }

  @override
  Future<List<CatalogOption>> loadGovernorates() async {
    callLog.add('governorates');
    await _delay();
    return governorates;
  }

  @override
  Future<List<AreaOption>> loadAreas({required int governorateId}) async {
    areaCalls++;
    callLog.add('areas:$governorateId');
    await _delay();
    return areas;
  }

  Future<void> _delay() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    // Wait for a gate if one is registered for the next pending call.
    for (final entry in gates.entries) {
      if (callLog.any((c) => c.startsWith(entry.key))) {
        await entry.value.future;
        gates.remove(entry.key);
        break;
      }
    }
  }
}

CatalogOption _option(int id, String ar, String en) =>
    CatalogOption(id: id, code: 'c$id', nameAr: ar, nameEn: en);

GradeOption _grade(int id, int number) => GradeOption(
  id: id,
  nameAr: 'الصف $number',
  nameEn: 'Grade $number',
  gradeNumber: number,
);

void main() {
  late _FakeCatalog catalog;
  late RegistrationCubit cubit;

  RegistrationCubit build() =>
      RegistrationCubit(_RegistrationOnly(), catalog: catalog);

  setUp(() {
    catalog = _FakeCatalog();
  });

  tearDown(() async {
    await cubit.close();
  });

  group('initial catalog load', () {
    test('loads programs, stages, and governorates', () async {
      catalog
        ..programs = [_option(1, 'عام', 'General')]
        ..stages = [_option(2, 'ثانوي', 'Secondary')]
        ..governorates = [_option(3, 'القاهرة', 'Cairo')];
      cubit = build();
      await cubit.loadCatalog();
      expect(cubit.state.programs.single.id, 1);
      expect(cubit.state.stages.single.id, 2);
      expect(cubit.state.governorates.single.id, 3);
      expect(
        catalog.callLog,
        containsAll(['programs', 'stages', 'governorates']),
      );
    });
  });

  group('dependent education selection', () {
    test('selecting a program loads its grades', () async {
      catalog
        ..programs = [_option(1, 'عام', 'General')]
        ..stages = [_option(2, 'ثانوي', 'Secondary')]
        ..grades = [_grade(10, 1), _grade(11, 2)];
      cubit = build();
      await cubit.loadCatalog();
      cubit.selectProgram(1);
      cubit.selectStage(2);
      await cubit.loadGrades();
      expect(catalog.callLog, contains('grades:1:2'));
      expect(cubit.state.grades.map((g) => g.gradeNumber), [1, 2]);
    });

    test('selecting a grade loads its tracks', () async {
      catalog
        ..grades = [_grade(10, 2)]
        ..tracks = [
          TrackOption(
            id: 20,
            code: 'science',
            nameAr: 'علمي',
            nameEn: 'Science',
            minGradeNumber: 2,
            maxGradeNumber: 3,
          ),
        ];
      cubit = build();
      cubit.selectProgram(1);
      cubit.selectStage(2);
      cubit.selectGrade(10, gradeNumber: 2);
      await cubit.loadTracks();
      expect(catalog.callLog, contains('tracks:1:2:2'));
      expect(cubit.state.tracks.single.id, 20);
    });

    test('an empty track list means no track applies', () async {
      catalog.grades = [_grade(10, 1)];
      cubit = build();
      cubit.selectProgram(1);
      cubit.selectStage(1);
      cubit.selectGrade(10, gradeNumber: 1);
      await cubit.loadTracks();
      expect(cubit.state.tracks, isEmpty);
      expect(cubit.state.requiresTrack, isFalse);
    });

    test('changing the program clears the grade and track', () async {
      cubit = build();
      cubit.selectProgram(1);
      cubit.selectStage(2);
      cubit.selectGrade(10, gradeNumber: 2);
      cubit.selectTrack(20);
      expect(cubit.state.draft.gradeId, 10);
      expect(cubit.state.draft.trackId, 20);

      cubit.selectProgram(9);
      expect(cubit.state.draft.stageId, isNull);
      expect(cubit.state.draft.gradeId, isNull);
      expect(cubit.state.draft.trackId, isNull);
      expect(cubit.state.grades, isEmpty);
      expect(cubit.state.tracks, isEmpty);
    });

    test('changing the stage clears the grade and track', () async {
      cubit = build();
      cubit.selectProgram(1);
      cubit.selectStage(2);
      cubit.selectGrade(10, gradeNumber: 2);
      cubit.selectTrack(20);

      cubit.selectStage(5);
      expect(cubit.state.draft.gradeId, isNull);
      expect(cubit.state.draft.trackId, isNull);
    });

    test('changing the grade clears the track', () async {
      cubit = build();
      cubit.selectProgram(1);
      cubit.selectStage(2);
      cubit.selectGrade(10, gradeNumber: 2);
      cubit.selectTrack(20);

      cubit.selectGrade(11, gradeNumber: 3);
      expect(cubit.state.draft.gradeId, 11);
      expect(cubit.state.draft.trackId, isNull);
    });
  });

  group('dependent location selection', () {
    test('selecting a governorate loads its areas', () async {
      catalog
        ..governorates = [_option(1, 'القاهرة', 'Cairo')]
        ..areas = [
          AreaOption(
            id: 100,
            governorateId: 1,
            code: 'nasr_city',
            nameAr: 'مدينة نصر',
            nameEn: 'Nasr City',
            areaType: 'city',
          ),
        ];
      cubit = build();
      await cubit.loadCatalog();
      cubit.selectGovernorate(1);
      await cubit.loadAreas();
      expect(catalog.callLog, contains('areas:1'));
      expect(cubit.state.areas.single.id, 100);
    });

    test('changing the governorate clears the area selection', () async {
      cubit = build();
      cubit.selectGovernorate(1);
      cubit.selectArea(100);
      expect(cubit.state.draft.areaId, 100);

      cubit.selectGovernorate(2);
      expect(cubit.state.draft.governorateId, 2);
      expect(cubit.state.draft.areaId, isNull);
      expect(cubit.state.areas, isEmpty);
    });
  });

  group('race handling', () {
    test('a stale grade response cannot overwrite a newer selection', () async {
      // Two requests: the first is slow, the second is fast.
      catalog.latency = Duration.zero;
      cubit = build();

      // First selection for program 1 stage 2.
      catalog.grades = [_grade(10, 1)];
      cubit.selectProgram(1);
      cubit.selectStage(2);
      final first = cubit.loadGrades();

      // Change the selection before the first completes.
      catalog.grades = [_grade(11, 2), _grade(12, 3)];
      cubit.selectProgram(3);
      cubit.selectStage(4);
      final second = cubit.loadGrades();

      await first;
      await second;

      // The state must reflect the newest selection, never the stale one.
      expect(catalog.callLog.where((c) => c.startsWith('grades:')).length, 2);
      expect(cubit.state.draft.gradeId, isNull);
    });

    test(
      'a stale area response cannot overwrite a newer governorate',
      () async {
        cubit = build();
        catalog.areas = [
          AreaOption(
            id: 100,
            governorateId: 1,
            code: 'a',
            nameAr: 'أ',
            nameEn: 'A',
            areaType: 'city',
          ),
        ];
        cubit.selectGovernorate(1);
        final first = cubit.loadAreas();

        catalog.areas = [
          AreaOption(
            id: 200,
            governorateId: 2,
            code: 'b',
            nameAr: 'ب',
            nameEn: 'B',
            areaType: 'city',
          ),
        ];
        cubit.selectGovernorate(2);
        final second = cubit.loadAreas();

        await first;
        await second;
        // Only the areas for the current governorate are shown.
        expect(cubit.state.areas.single.governorateId, 2);
      },
    );
  });

  group('loading and empty states', () {
    test('a catalog failure surfaces an error state, not a crash', () async {
      cubit = build();
      catalog.latency = Duration.zero;
      // Replace the catalog with a throwing one through a new cubit.
      final throwing = RegistrationCubit(
        _RegistrationOnly(),
        catalog: _ThrowingCatalog(),
      );
      await throwing.loadCatalog();
      expect(throwing.state.catalogError, isTrue);
      expect(throwing.state.programs, isEmpty);
      await throwing.close();
    });

    test('an empty catalog leaves empty lists and no error', () async {
      cubit = build();
      await cubit.loadCatalog();
      expect(cubit.state.programs, isEmpty);
      expect(cubit.state.stages, isEmpty);
      expect(cubit.state.governorates, isEmpty);
      expect(cubit.state.catalogError, isFalse);
      expect(cubit.state.catalogLoading, isFalse);
    });
  });
}

/// A repository that only provides registration, delegating the catalog to
/// the test's fake.
class _RegistrationOnly implements RegistrationRepository {
  @override
  Future<PhoneAvailability> checkPhoneAvailability(String phone) async =>
      const PhoneAvailability(
        status: PhoneAvailabilityStatus.available,
        phone: '+201234567890',
      );

  @override
  Future<void> registerStudent(StudentRegistrationRequest request) async {}
}

class _ThrowingCatalog implements CatalogRepository {
  @override
  Future<List<CatalogOption>> loadPrograms() async =>
      throw Exception('db down');

  @override
  Future<List<CatalogOption>> loadStages() async => const [];

  @override
  Future<List<GradeOption>> loadGrades({
    required int programId,
    required int stageId,
  }) async => const [];

  @override
  Future<List<TrackOption>> loadTracks({
    required int programId,
    required int stageId,
    required int gradeNumber,
  }) async => const [];

  @override
  Future<List<GradeSubjectOption>> loadGradeSubjects({
    required int gradeId,
  }) async => const [];

  @override
  Future<List<TrackSubjectOption>> loadTrackSubjects({
    required int trackId,
    required int gradeId,
  }) async => const [];

  @override
  Future<List<CatalogOption>> loadGovernorates() async => const [];

  @override
  Future<List<AreaOption>> loadAreas({required int governorateId}) async =>
      const [];
}

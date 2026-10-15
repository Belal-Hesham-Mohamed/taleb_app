import 'dart:async';

import '../../domain/entities/catalog.dart';
import '../../domain/repositories/registration_repository.dart';

/// An in-memory stand-in for [RegistrationRepository] and [CatalogRepository]
/// used only to drive the registration flow on an emulator without a
/// reachable backend.
///
/// Enabled by the debug-only `FAKE_REGISTRATION` flag. It must never run in a
/// release build: it accepts any password and pretends account creation
/// succeeded, so it proves UI behavior only, never real authentication.
class FakeRegistrationRepository
    implements RegistrationRepository, CatalogRepository {
  FakeRegistrationRepository({this.takenNumbers = const [], this.delay});

  /// Numbers that report as already registered.
  final List<String> takenNumbers;

  /// Simulated network latency so loading states are observable.
  final Duration? delay;

  /// Set to make the next availability check fail.
  bool failNextAvailabilityCheck = false;

  /// Set to make the next registration fail.
  bool failNextRegistration = false;

  /// The failure kind used when [failNextRegistration] is set.
  RegistrationFailureKind failureKind = RegistrationFailureKind.unexpected;

  /// A gate that holds an availability check open until completed.
  Completer<void>? availabilityGate;

  /// Numbers successfully "created" by this fake.
  final List<String> createdNumbers = [];

  int availabilityCalls = 0;
  int registrationCalls = 0;

  final _mutex = <Completer<void>>[];

  /// Serializes registration so a concurrent second call queues behind the
  /// first instead of racing it.
  Future<void> _serialize() async {
    while (_mutex.isNotEmpty) {
      await _mutex.first.future;
    }
    final completer = Completer<void>();
    _mutex.add(completer);
  }

  void _release() {
    if (_mutex.isNotEmpty) {
      final completer = _mutex.removeAt(0);
      if (!completer.isCompleted) completer.complete();
    }
  }

  @override
  Future<PhoneAvailability> checkPhoneAvailability(String phone) async {
    availabilityCalls++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (availabilityGate != null) await availabilityGate!.future;
    if (failNextAvailabilityCheck) {
      failNextAvailabilityCheck = false;
      throw const RegistrationFailure(RegistrationFailureKind.network);
    }
    final taken =
        takenNumbers.contains(phone) || createdNumbers.contains(phone);
    return PhoneAvailability(
      status: taken
          ? PhoneAvailabilityStatus.taken
          : PhoneAvailabilityStatus.available,
      phone: phone,
    );
  }

  @override
  Future<void> registerStudent(StudentRegistrationRequest request) async {
    await _serialize();
    try {
      registrationCalls++;
      if (delay != null) await Future<void>.delayed(delay!);
      if (failNextRegistration) {
        failNextRegistration = false;
        throw RegistrationFailure(failureKind);
      }
      if (takenNumbers.contains(request.phone)) {
        throw const RegistrationFailure(
          RegistrationFailureKind.phoneAlreadyRegistered,
        );
      }
      createdNumbers.add(request.phone);
    } finally {
      _release();
    }
  }

  // ---- Catalog ----

  /// A small catalog so the emulator flow can be driven end to end.
  static final _programs = <CatalogOption>[
    CatalogOption(id: 1, code: 'general', nameAr: 'عام', nameEn: 'General'),
    CatalogOption(id: 2, code: 'azhar', nameAr: 'أزهري', nameEn: 'Al-Azhar'),
    CatalogOption(
      id: 3,
      code: 'egyptian_baccalaureate',
      nameAr: 'البكالوريا المصرية',
      nameEn: 'Egyptian Baccalaureate',
    ),
  ];

  static final _stages = <CatalogOption>[
    CatalogOption(id: 1, code: 'primary', nameAr: 'ابتدائي', nameEn: 'Primary'),
    CatalogOption(
      id: 2,
      code: 'preparatory',
      nameAr: 'إعدادي',
      nameEn: 'Preparatory',
    ),
    CatalogOption(
      id: 3,
      code: 'secondary',
      nameAr: 'ثانوي',
      nameEn: 'Secondary',
    ),
  ];

  @override
  Future<List<CatalogOption>> loadPrograms() async => _withDelay(_programs);

  @override
  Future<List<CatalogOption>> loadStages() async => _withDelay(_stages);

  @override
  Future<List<GradeOption>> loadGrades({
    required int programId,
    required int stageId,
  }) async {
    final count = switch (stageId) {
      1 => 6,
      2 => 3,
      _ => 3,
    };
    final grades = [
      for (var number = 1; number <= count; number++)
        GradeOption(
          id: stageId * 100 + number,
          nameAr: 'الصف $number',
          nameEn: 'Grade $number',
          gradeNumber: number,
        ),
    ];
    return _withDelay(grades);
  }

  @override
  Future<List<TrackOption>> loadTracks({
    required int programId,
    required int stageId,
    required int gradeNumber,
  }) async {
    // Only the secondary stage has tracks, and only for grade 2 and 3.
    if (stageId != 3 || gradeNumber < 2) return _withDelay(const []);
    final tracks = [
      TrackOption(
        id: 300 + gradeNumber,
        code: 'science',
        nameAr: 'علمي',
        nameEn: 'Science',
        minGradeNumber: 2,
        maxGradeNumber: 3,
      ),
      TrackOption(
        id: 400 + gradeNumber,
        code: 'literary',
        nameAr: 'أدبي',
        nameEn: 'Literary',
        minGradeNumber: 2,
        maxGradeNumber: 3,
      ),
    ];
    return _withDelay(tracks);
  }

  @override
  Future<List<GradeSubjectOption>> loadGradeSubjects({
    required int gradeId,
  }) async {
    return _withDelay([
      GradeSubjectOption(
        subject: SubjectOption(
          id: gradeId * 10,
          code: 'arabic',
          nameAr: 'اللغة العربية',
          nameEn: 'Arabic',
        ),
        isRequired: true,
        countsTowardTotal: true,
      ),
    ]);
  }

  @override
  Future<List<TrackSubjectOption>> loadTrackSubjects({
    required int trackId,
    required int gradeId,
  }) async {
    return _withDelay([
      TrackSubjectOption(
        subject: SubjectOption(
          id: trackId * 10,
          code: 'math',
          nameAr: 'الرياضيات',
          nameEn: 'Mathematics',
        ),
        subjectRole: 'required',
        choiceGroup: null,
        isAdvanced: true,
        isRequired: true,
        countsTowardTotal: true,
      ),
    ]);
  }

  @override
  Future<List<CatalogOption>> loadGovernorates() async {
    return _withDelay(const [
      CatalogOption(id: 1, code: 'cairo', nameAr: 'القاهرة', nameEn: 'Cairo'),
      CatalogOption(id: 2, code: 'giza', nameAr: 'الجيزة', nameEn: 'Giza'),
    ]);
  }

  @override
  Future<List<AreaOption>> loadAreas({required int governorateId}) async {
    return _withDelay([
      AreaOption(
        id: governorateId * 100,
        governorateId: governorateId,
        code: 'city',
        nameAr: 'مدينة $governorateId',
        nameEn: 'City $governorateId',
        areaType: 'city',
      ),
    ]);
  }

  Future<List<T>> _withDelay<T>(List<T> value) async {
    if (delay != null) await Future<void>.delayed(delay!);
    return value;
  }
}

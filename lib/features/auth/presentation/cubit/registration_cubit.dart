import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/catalog.dart';
import '../../domain/entities/education_path.dart';
import '../../domain/entities/registration_draft.dart';
import '../../domain/repositories/registration_repository.dart';
import '../../domain/validation/registration_draft.dart' as validation;

/// The steps of the student registration journey, in order.
enum RegistrationStep { credentials, personal, education, review, success }

/// Presentation state for the student registration journey.
///
/// Business rules live in the domain layer: this state only exposes the
/// validation results and the draft the presentation renders.
class RegistrationState {
  const RegistrationState({
    this.step = RegistrationStep.credentials,
    this.draft = const RegistrationDraft.empty(),
    this.checkingPhone = false,
    this.phoneAvailability = const PhoneAvailability(
      status: PhoneAvailabilityStatus.unavailable,
    ),
    this.phoneAvailabilityError,
    this.credentials = const validation.CredentialsIssues(),
    this.personal = const validation.PersonalIssues(),
    this.education = const validation.EducationIssues(),
    this.submitting = false,
    this.failure,
    this.programs = const [],
    this.stages = const [],
    this.grades = const [],
    this.tracks = const [],
    this.governorates = const [],
    this.areas = const [],
    this.gradeSubjects = const [],
    this.trackSubjects = const [],
    this.rootStatus = CatalogQueryStatus.idle,
    this.gradesStatus = CatalogQueryStatus.idle,
    this.tracksStatus = CatalogQueryStatus.idle,
    this.areasStatus = CatalogQueryStatus.idle,
    this.gradeSubjectsStatus = CatalogQueryStatus.idle,
    this.trackSubjectsStatus = CatalogQueryStatus.idle,
  });

  final RegistrationStep step;
  final RegistrationDraft draft;
  final bool checkingPhone;

  /// The last availability answer. A failed check is never `available`.
  final PhoneAvailability phoneAvailability;

  /// Non-null when the availability check could not be completed, so the user
  /// must not be allowed to continue as if the number were free.
  final String? phoneAvailabilityError;

  final validation.CredentialsIssues credentials;
  final validation.PersonalIssues personal;
  final validation.EducationIssues education;
  final bool submitting;

  /// Set when account creation failed. Success is never emitted on failure.
  final RegistrationFailureKind? failure;

  // ---- Catalog options, loaded from the database ----

  final List<CatalogOption> programs;
  final List<CatalogOption> stages;
  final List<GradeOption> grades;
  final List<TrackOption> tracks;
  final List<CatalogOption> governorates;
  final List<AreaOption> areas;
  final List<GradeSubjectOption> gradeSubjects;
  final List<TrackSubjectOption> trackSubjects;

  final CatalogQueryStatus rootStatus;
  final CatalogQueryStatus gradesStatus;
  final CatalogQueryStatus tracksStatus;
  final CatalogQueryStatus areasStatus;
  final CatalogQueryStatus gradeSubjectsStatus;
  final CatalogQueryStatus trackSubjectsStatus;

  /// True while any catalog request is in flight.
  bool get catalogLoading =>
      rootStatus.isLoading ||
      gradesStatus.isLoading ||
      tracksStatus.isLoading ||
      areasStatus.isLoading ||
      gradeSubjectsStatus.isLoading ||
      trackSubjectsStatus.isLoading;

  /// True when any catalog request failed.
  bool get catalogError =>
      rootStatus.isFailure ||
      gradesStatus.isFailure ||
      tracksStatus.isFailure ||
      areasStatus.isFailure ||
      gradeSubjectsStatus.isFailure ||
      trackSubjectsStatus.isFailure;

  bool get phoneTaken =>
      phoneAvailability.status == PhoneAvailabilityStatus.taken;

  /// Whether the selected education path needs a track selection.
  bool get requiresTrack => draft.requiresTrack;

  RegistrationState copyWith({
    RegistrationStep? step,
    RegistrationDraft? draft,
    bool? checkingPhone,
    PhoneAvailability? phoneAvailability,
    String? phoneAvailabilityError,
    bool clearPhoneAvailabilityError = false,
    validation.CredentialsIssues? credentials,
    validation.PersonalIssues? personal,
    validation.EducationIssues? education,
    bool? submitting,
    RegistrationFailureKind? failure,
    bool clearFailure = false,
    List<CatalogOption>? programs,
    List<CatalogOption>? stages,
    List<GradeOption>? grades,
    List<TrackOption>? tracks,
    List<CatalogOption>? governorates,
    List<AreaOption>? areas,
    List<GradeSubjectOption>? gradeSubjects,
    List<TrackSubjectOption>? trackSubjects,
    CatalogQueryStatus? rootStatus,
    CatalogQueryStatus? gradesStatus,
    CatalogQueryStatus? tracksStatus,
    CatalogQueryStatus? areasStatus,
    CatalogQueryStatus? gradeSubjectsStatus,
    CatalogQueryStatus? trackSubjectsStatus,
  }) => RegistrationState(
    step: step ?? this.step,
    draft: draft ?? this.draft,
    checkingPhone: checkingPhone ?? this.checkingPhone,
    phoneAvailability: phoneAvailability ?? this.phoneAvailability,
    phoneAvailabilityError: clearPhoneAvailabilityError
        ? null
        : (phoneAvailabilityError ?? this.phoneAvailabilityError),
    credentials: credentials ?? this.credentials,
    personal: personal ?? this.personal,
    education: education ?? this.education,
    submitting: submitting ?? this.submitting,
    failure: clearFailure ? null : (failure ?? this.failure),
    programs: programs ?? this.programs,
    stages: stages ?? this.stages,
    grades: grades ?? this.grades,
    tracks: tracks ?? this.tracks,
    governorates: governorates ?? this.governorates,
    areas: areas ?? this.areas,
    gradeSubjects: gradeSubjects ?? this.gradeSubjects,
    trackSubjects: trackSubjects ?? this.trackSubjects,
    rootStatus: rootStatus ?? this.rootStatus,
    gradesStatus: gradesStatus ?? this.gradesStatus,
    tracksStatus: tracksStatus ?? this.tracksStatus,
    areasStatus: areasStatus ?? this.areasStatus,
    gradeSubjectsStatus: gradeSubjectsStatus ?? this.gradeSubjectsStatus,
    trackSubjectsStatus: trackSubjectsStatus ?? this.trackSubjectsStatus,
  );
}

/// Orchestrates the student registration journey.
///
/// Phone-number uniqueness is enforced by the trusted backend: the
/// availability check is a convenience that may report [PhoneAvailabilityStatus
/// .taken], and the final creation call rejects duplicates independently.
/// A failed availability check never allows progression.
class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit(this._repository, {CatalogRepository? catalog})
    : _catalog = catalog ?? _tryCatalog(_repository),
      super(const RegistrationState());

  final RegistrationRepository _repository;
  final CatalogRepository? _catalog;

  /// Independent request tokens so a governorate change cannot drop a grade
  /// response, and a stale result cannot leave another catalog spinner stuck.
  int _rootGeneration = 0;
  int _gradesGeneration = 0;
  int _tracksGeneration = 0;
  int _areasGeneration = 0;
  int _gradeSubjectsGeneration = 0;
  int _trackSubjectsGeneration = 0;

  /// True when no catalog source is available, so catalog-dependent UI must
  /// stay disabled rather than crash.
  bool get hasCatalog => _catalog != null;

  void updatePhone(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(phone: value)));

  void updatePassword(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(password: value)));

  void updateConfirmPassword(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(confirmPassword: value)));

  void updateEmail(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(email: value)));

  void updateFullName(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(fullName: value)));

  void updateDateOfBirth(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(dateOfBirth: value)));

  void updateGender(Gender? value) =>
      emit(state.copyWith(draft: state.draft.copyWith(gender: value)));

  void updateStudentId(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(studentId: value)));

  void updateGuardianPhone(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(guardianPhone: value)));

  void updateGuardianId(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(guardianId: value)));

  void updateGovernorate(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(governorate: value)));

  void updateArea(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(area: value)));

  void updateStage(EducationalStage? stage) => emit(
    state.copyWith(
      draft: stage == null ? state.draft : state.draft.withStage(stage),
    ),
  );

  void updateType(EducationType? type) => emit(
    state.copyWith(
      draft: type == null ? state.draft : state.draft.withType(type),
    ),
  );

  void updateSystem(AcademicSystem? system) => emit(
    state.copyWith(
      draft: system == null ? state.draft : state.draft.withSystem(system),
    ),
  );

  void updateGrade(StudyGrade? grade) => emit(
    state.copyWith(
      draft: grade == null ? state.draft : state.draft.withGrade(grade),
    ),
  );

  void updateTrack(AcademicTrack? track) =>
      emit(state.copyWith(draft: state.draft.copyWith(track: track)));

  void updateSchool(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(school: value)));

  // ---- Catalog-driven selection ----

  /// Loads the program, stage, and governorate catalogs.
  Future<void> loadCatalog() async {
    final catalog = _catalog;
    if (catalog == null) return;
    final generation = ++_rootGeneration;
    emit(state.copyWith(rootStatus: CatalogQueryStatus.loading));
    try {
      final results = await (
        catalog.loadPrograms(),
        catalog.loadStages(),
        catalog.loadGovernorates(),
      ).wait;
      if (generation != _rootGeneration) return;
      emit(
        state.copyWith(
          rootStatus: CatalogQueryStatus.success,
          programs: results.$1,
          stages: results.$2,
          governorates: results.$3,
        ),
      );
    } catch (_) {
      if (generation != _rootGeneration) return;
      emit(state.copyWith(rootStatus: CatalogQueryStatus.failure));
    }
  }

  /// Selects the education program and clears the dependent selections.
  void selectProgram(int programId, {String? code}) {
    _bumpEducationDependents();
    emit(
      state.copyWith(
        draft: state.draft.withProgram(programId, code: code),
        grades: const [],
        tracks: const [],
        gradeSubjects: const [],
        trackSubjects: const [],
        gradesStatus: CatalogQueryStatus.idle,
        tracksStatus: CatalogQueryStatus.idle,
        gradeSubjectsStatus: CatalogQueryStatus.idle,
        trackSubjectsStatus: CatalogQueryStatus.idle,
      ),
    );
  }

  /// Selects the education stage and clears the dependent selections.
  void selectStage(int stageId, {String? code}) {
    _bumpEducationDependents();
    emit(
      state.copyWith(
        draft: state.draft.withStageId(stageId, code: code),
        grades: const [],
        tracks: const [],
        gradeSubjects: const [],
        trackSubjects: const [],
        gradesStatus: CatalogQueryStatus.idle,
        tracksStatus: CatalogQueryStatus.idle,
        gradeSubjectsStatus: CatalogQueryStatus.idle,
        trackSubjectsStatus: CatalogQueryStatus.idle,
      ),
    );
  }

  /// Selects the grade and clears the track selection.
  void selectGrade(int gradeId, {int? gradeNumber}) {
    _tracksGeneration++;
    _gradeSubjectsGeneration++;
    _trackSubjectsGeneration++;
    emit(
      state.copyWith(
        draft: state.draft.withGradeId(gradeId, gradeNumber: gradeNumber),
        tracks: const [],
        gradeSubjects: const [],
        trackSubjects: const [],
        tracksStatus: CatalogQueryStatus.idle,
        gradeSubjectsStatus: CatalogQueryStatus.idle,
        trackSubjectsStatus: CatalogQueryStatus.idle,
      ),
    );
  }

  /// Selects the track. Passing null clears it.
  void selectTrack(int? trackId, {String? code}) {
    _trackSubjectsGeneration++;
    emit(
      state.copyWith(
        draft: state.draft.withTrackId(trackId, code: code),
        trackSubjects: const [],
        trackSubjectsStatus: trackId == null
            ? CatalogQueryStatus.idle
            : CatalogQueryStatus.idle,
      ),
    );
  }

  /// Selects the governorate and clears the area selection and legacy text.
  void selectGovernorate(int governorateId, {String? code}) {
    _areasGeneration++;
    emit(
      state.copyWith(
        draft: state.draft.withGovernorate(governorateId, code: code),
        areas: const [],
        areasStatus: CatalogQueryStatus.idle,
      ),
    );
  }

  /// Selects the area.
  void selectArea(int areaId, {String? code}) {
    emit(state.copyWith(draft: state.draft.withArea(areaId, code: code)));
  }

  void _bumpEducationDependents() {
    _gradesGeneration++;
    _tracksGeneration++;
    _gradeSubjectsGeneration++;
    _trackSubjectsGeneration++;
  }

  void updateSchoolName(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(schoolName: value)));

  void updateSchoolType(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(schoolType: value)));

  /// Loads the grades for the selected program and stage.
  ///
  /// The response is discarded when the selection changed while the request
  /// was in flight.
  Future<void> loadGrades() async {
    final catalog = _catalog;
    final programId = state.draft.programId;
    final stageId = state.draft.stageId;
    if (catalog == null || programId == null || stageId == null) return;
    final generation = ++_gradesGeneration;
    emit(state.copyWith(gradesStatus: CatalogQueryStatus.loading, grades: const []));
    try {
      final grades = await catalog.loadGrades(
        programId: programId,
        stageId: stageId,
      );
      if (generation != _gradesGeneration) return;
      emit(
        state.copyWith(gradesStatus: CatalogQueryStatus.success, grades: grades),
      );
    } catch (_) {
      if (generation != _gradesGeneration) return;
      emit(
        state.copyWith(
          gradesStatus: CatalogQueryStatus.failure,
          grades: const [],
        ),
      );
    }
  }

  /// Loads the tracks for the selected program, stage, and grade.
  ///
  /// An empty result means no track applies, which is how primary and
  /// preparatory students are never asked for a specialization.
  Future<void> loadTracks() async {
    final catalog = _catalog;
    final programId = state.draft.programId;
    final stageId = state.draft.stageId;
    final gradeNumber = state.draft.gradeNumber;
    if (catalog == null ||
        programId == null ||
        stageId == null ||
        gradeNumber == null) {
      return;
    }
    final generation = ++_tracksGeneration;
    emit(state.copyWith(tracksStatus: CatalogQueryStatus.loading, tracks: const []));
    try {
      final tracks = await catalog.loadTracks(
        programId: programId,
        stageId: stageId,
        gradeNumber: gradeNumber,
      );
      if (generation != _tracksGeneration) return;
      emit(
        state.copyWith(tracksStatus: CatalogQueryStatus.success, tracks: tracks),
      );
    } catch (_) {
      if (generation != _tracksGeneration) return;
      emit(
        state.copyWith(
          tracksStatus: CatalogQueryStatus.failure,
          tracks: const [],
        ),
      );
    }
  }

  /// Loads the areas for the selected governorate.
  Future<void> loadAreas() async {
    final catalog = _catalog;
    final governorateId = state.draft.governorateId;
    if (catalog == null || governorateId == null) return;
    final generation = ++_areasGeneration;
    emit(state.copyWith(areasStatus: CatalogQueryStatus.loading, areas: const []));
    try {
      final areas = await catalog.loadAreas(governorateId: governorateId);
      if (generation != _areasGeneration) return;
      emit(state.copyWith(areasStatus: CatalogQueryStatus.success, areas: areas));
    } catch (_) {
      if (generation != _areasGeneration) return;
      emit(
        state.copyWith(
          areasStatus: CatalogQueryStatus.failure,
          areas: const [],
        ),
      );
    }
  }

  /// Loads the subjects for the selected grade into state.
  Future<void> loadGradeSubjects() async {
    final catalog = _catalog;
    final gradeId = state.draft.gradeId;
    if (catalog == null || gradeId == null) return;
    final generation = ++_gradeSubjectsGeneration;
    emit(
      state.copyWith(
        gradeSubjectsStatus: CatalogQueryStatus.loading,
        gradeSubjects: const [],
      ),
    );
    try {
      final subjects = await catalog.loadGradeSubjects(gradeId: gradeId);
      if (generation != _gradeSubjectsGeneration) return;
      emit(
        state.copyWith(
          gradeSubjectsStatus: CatalogQueryStatus.success,
          gradeSubjects: subjects,
        ),
      );
    } catch (_) {
      if (generation != _gradeSubjectsGeneration) return;
      emit(
        state.copyWith(
          gradeSubjectsStatus: CatalogQueryStatus.failure,
          gradeSubjects: const [],
        ),
      );
    }
  }

  /// Loads the subjects for the selected track and grade into state.
  Future<void> loadTrackSubjects() async {
    final catalog = _catalog;
    final trackId = state.draft.trackId;
    final gradeId = state.draft.gradeId;
    if (catalog == null || trackId == null || gradeId == null) {
      emit(
        state.copyWith(
          trackSubjects: const [],
          trackSubjectsStatus: CatalogQueryStatus.idle,
        ),
      );
      return;
    }
    final generation = ++_trackSubjectsGeneration;
    emit(
      state.copyWith(
        trackSubjectsStatus: CatalogQueryStatus.loading,
        trackSubjects: const [],
      ),
    );
    try {
      final subjects = await catalog.loadTrackSubjects(
        trackId: trackId,
        gradeId: gradeId,
      );
      if (generation != _trackSubjectsGeneration) return;
      emit(
        state.copyWith(
          trackSubjectsStatus: CatalogQueryStatus.success,
          trackSubjects: subjects,
        ),
      );
    } catch (_) {
      if (generation != _trackSubjectsGeneration) return;
      emit(
        state.copyWith(
          trackSubjectsStatus: CatalogQueryStatus.failure,
          trackSubjects: const [],
        ),
      );
    }
  }

  validation.PersonalIssues _personalIssues() => validation.personalIssues(
    state.draft,
    areas: state.areas,
    requireCatalogIds: hasCatalog,
    areasStatus: state.areasStatus,
  );

  validation.EducationIssues _educationIssues() => validation.educationIssues(
    state.draft,
    availableTracks: state.tracks,
    availableGrades: state.grades,
    requireCatalogIds: hasCatalog,
    gradesStatus: state.gradesStatus,
    tracksStatus: state.tracksStatus,
  );

  bool _catalogSelectionsReady() {
    if (!hasCatalog) return true;
    if (!state.rootStatus.isSuccess) return false;
    if (state.programs.every((p) => p.id != state.draft.programId)) {
      return false;
    }
    if (state.stages.every((s) => s.id != state.draft.stageId)) return false;
    if (!state.gradesStatus.isSuccess) return false;
    if (state.grades.every((g) => g.id != state.draft.gradeId)) return false;
    if (!state.tracksStatus.isSuccess) return false;
    if (state.tracks.isNotEmpty) {
      if (state.tracks.every((t) => t.id != state.draft.trackId)) return false;
    } else if (state.draft.trackId != null) {
      return false;
    }
    if (!state.areasStatus.isSuccess) return false;
    final area = state.areas.where((a) => a.id == state.draft.areaId).firstOrNull;
    if (area == null || area.governorateId != state.draft.governorateId) {
      return false;
    }
    return true;
  }

  /// Validates the credentials step and, when valid, checks availability.
  ///
  /// Progression happens only when the backend confirms the number is
  /// available. A taken number or a failed check keeps the user on this step.
  Future<void> checkPhone() async {
    if (state.checkingPhone) return;
    final issues = validation.credentialsIssues(state.draft);
    emit(
      state.copyWith(
        credentials: issues,
        clearPhoneAvailabilityError: true,
        clearFailure: true,
      ),
    );
    if (!issues.isValid) return;

    final phone = state.draft.normalizedPhone!;
    emit(
      state.copyWith(checkingPhone: true, clearPhoneAvailabilityError: true),
    );
    PhoneAvailability availability;
    try {
      availability = await _repository.checkPhoneAvailability(phone);
    } on RegistrationFailure catch (failure) {
      emit(
        state.copyWith(
          checkingPhone: false,
          phoneAvailability: const PhoneAvailability(
            status: PhoneAvailabilityStatus.unavailable,
          ),
          phoneAvailabilityError: failure.kind.name,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        checkingPhone: false,
        phoneAvailability: availability,
        step: availability.available
            ? RegistrationStep.personal
            : RegistrationStep.credentials,
        phoneAvailabilityError: availability.available
            ? null
            : (isPhoneAvailabilityFailure(availability)
                  ? 'unavailable'
                  : 'taken'),
      ),
    );
  }

  /// Validates the personal-information step and advances when valid.
  Future<void> submitPersonal() async {
    final issues = _personalIssues();
    emit(state.copyWith(personal: issues, clearFailure: true));
    if (!issues.isValid) return;
    emit(state.copyWith(step: RegistrationStep.education));
  }

  /// Validates the educational step and advances to review when valid.
  Future<void> submitEducation() async {
    final issues = _educationIssues();
    emit(state.copyWith(education: issues, clearFailure: true));
    if (!issues.isValid) return;
    emit(state.copyWith(step: RegistrationStep.review));
  }

  /// Revalidates every step and creates the account.
  ///
  /// Never emits success when the operation failed. Repeated taps while a
  /// request is in flight are ignored so a duplicate account cannot be
  /// created.
  Future<void> createAccount() async {
    if (state.submitting) return;
    final credentials = validation.credentialsIssues(state.draft);
    final personal = _personalIssues();
    final education = _educationIssues();
    emit(
      state.copyWith(
        credentials: credentials,
        personal: personal,
        education: education,
        clearFailure: true,
      ),
    );
    if (!credentials.isValid) {
      emit(state.copyWith(step: RegistrationStep.credentials));
      return;
    }
    if (!personal.isValid) {
      emit(state.copyWith(step: RegistrationStep.personal));
      return;
    }
    if (!education.isValid) {
      emit(state.copyWith(step: RegistrationStep.education));
      return;
    }
    if (!_catalogSelectionsReady()) {
      if (!personal.isValid) {
        emit(state.copyWith(step: RegistrationStep.personal));
        return;
      }
      emit(state.copyWith(step: RegistrationStep.education));
      return;
    }

    emit(state.copyWith(submitting: true));
    try {
      await _repository.registerStudent(
        StudentRegistrationRequest(
          phone: state.draft.normalizedPhone!,
          password: state.draft.password,
          fullName: state.draft.fullName.trim(),
          draft: state.draft,
        ),
      );
      emit(state.copyWith(submitting: false, step: RegistrationStep.success));
    } on RegistrationFailure catch (failure) {
      emit(
        state.copyWith(
          submitting: false,
          step: RegistrationStep.review,
          failure: failure.kind,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          submitting: false,
          step: RegistrationStep.review,
          failure: RegistrationFailureKind.unexpected,
        ),
      );
    }
  }

  /// Returns to the previous step, preserving all entered values.
  void goBack() {
    switch (state.step) {
      case RegistrationStep.credentials:
        break;
      case RegistrationStep.personal:
        emit(state.copyWith(step: RegistrationStep.credentials));
      case RegistrationStep.education:
        emit(state.copyWith(step: RegistrationStep.personal));
      case RegistrationStep.review:
        emit(state.copyWith(step: RegistrationStep.education));
      case RegistrationStep.success:
        break;
    }
  }

  /// Jumps back to a step from the review screen. Dependent educational
  /// selections are cleared when a parent edit makes them invalid, which the
  /// draft enforces in [RegistrationDraft.withStage].
  void editStep(RegistrationStep step) {
    if (step == RegistrationStep.success) return;
    emit(state.copyWith(step: step));
  }
}

/// Treats a registration repository as a catalog repository when it provides
/// both, which the Supabase implementation does. Returns null when it does
/// not, so a repository without catalog support can still be used for the
/// parts of the flow that do not need the catalog.
CatalogRepository? _tryCatalog(RegistrationRepository repository) {
  if (repository is CatalogRepository) {
    return repository as CatalogRepository;
  }
  return null;
}

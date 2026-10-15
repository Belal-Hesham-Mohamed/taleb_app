import 'package:flutter_bloc/flutter_bloc.dart';

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

  bool get phoneTaken =>
      phoneAvailability.status == PhoneAvailabilityStatus.taken;

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
  );
}

/// Orchestrates the student registration journey.
///
/// Phone-number uniqueness is enforced by the trusted backend: the
/// availability check is a convenience that may report [PhoneAvailabilityStatus
/// .taken], and the final creation call rejects duplicates independently.
/// A failed availability check never allows progression.
class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit(this._repository) : super(const RegistrationState());

  final RegistrationRepository _repository;

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
    final issues = validation.personalIssues(state.draft);
    emit(state.copyWith(personal: issues, clearFailure: true));
    if (!issues.isValid) return;
    emit(state.copyWith(step: RegistrationStep.education));
  }

  /// Validates the educational step and advances to review when valid.
  Future<void> submitEducation() async {
    final issues = validation.educationIssues(state.draft);
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
    final personal = validation.personalIssues(state.draft);
    final education = validation.educationIssues(state.draft);
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

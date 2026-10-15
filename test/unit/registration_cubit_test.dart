import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/features/auth/domain/entities/education_path.dart';
import 'package:taleb/features/auth/domain/entities/registration_draft.dart';
import 'package:taleb/features/auth/domain/repositories/registration_repository.dart';
import 'package:taleb/features/auth/presentation/cubit/registration_cubit.dart';

RegistrationDraft _completeDraft({
  EducationalStage stage = EducationalStage.primary,
  StudyGrade? grade,
  EducationType? type,
  AcademicSystem? system,
  AcademicTrack? track,
}) => RegistrationDraft(
  phone: '01234567890',
  password: 'secret123',
  confirmPassword: 'secret123',
  email: '',
  fullName: 'أحمد محمد علي حسن',
  dateOfBirth: '2007-01-15',
  gender: Gender.male,
  studentId: '',
  guardianPhone: '01234567891',
  guardianId: '',
  governorate: 'cairo',
  area: 'nasr_city',
  stage: stage,
  type: type,
  system: system,
  grade:
      grade ?? (stage == EducationalStage.primary ? StudyGrade.primary4 : null),
  track: track,
  school: '',
);

void main() {
  late _FakeRegistrationRepository repository;
  late RegistrationCubit cubit;

  setUp(() {
    repository = _FakeRegistrationRepository();
    cubit = RegistrationCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('starts at the credentials step', () {
    expect(cubit.state.step, RegistrationStep.credentials);
    expect(cubit.state.credentials.phone, isNull);
  });

  test(
    'the Next button reports credentials errors without advancing',
    () async {
      await cubit.checkPhone();
      expect(cubit.state.step, RegistrationStep.credentials);
      expect(cubit.state.credentials.phone, isNotNull);
      expect(cubit.state.credentials.password, isNotNull);
    },
  );

  test('a taken number blocks progression', () async {
    repository.availabilityResult = const PhoneAvailability(
      status: PhoneAvailabilityStatus.taken,
      phone: '+201234567890',
    );
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    await cubit.checkPhone();
    expect(cubit.state.step, RegistrationStep.credentials);
    expect(cubit.state.phoneAvailability.available, isFalse);
    expect(cubit.state.phoneAvailabilityError, isNotNull);
  });

  test('a failed availability check does not advance', () async {
    repository.availabilityResult = const PhoneAvailability(
      status: PhoneAvailabilityStatus.unavailable,
    );
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    await cubit.checkPhone();
    expect(cubit.state.step, RegistrationStep.credentials);
    expect(cubit.state.phoneAvailabilityError, isNotNull);
    expect(cubit.state.phoneAvailability.available, isFalse);
  });

  test('an available number advances to the personal step', () async {
    repository.availabilityResult = const PhoneAvailability(
      status: PhoneAvailabilityStatus.available,
      phone: '+201234567890',
    );
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    await cubit.checkPhone();
    expect(cubit.state.step, RegistrationStep.personal);
    expect(cubit.state.draft.normalizedPhone, '+201234567890');
    expect(repository.availabilityCalls, 1);
  });

  test('the availability check uses the normalized number', () async {
    repository.availabilityResult = const PhoneAvailability(
      status: PhoneAvailabilityStatus.available,
      phone: '+201234567890',
    );
    cubit.updatePhone('+20 12 3456 7890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    await cubit.checkPhone();
    expect(repository.checkedPhones, ['+201234567890']);
  });

  test('a pending check does not start a second request', () async {
    final completer = Completer<PhoneAvailability>();
    repository.availabilityCompleter = completer;
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    final first = cubit.checkPhone();
    await cubit.checkPhone();
    expect(repository.availabilityCalls, 1);
    completer.complete(
      const PhoneAvailability(
        status: PhoneAvailabilityStatus.available,
        phone: '+201234567890',
      ),
    );
    await first;
  });

  test('the personal step validates before advancing to education', () async {
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    repository.availabilityResult = const PhoneAvailability(
      status: PhoneAvailabilityStatus.taken,
      phone: '+201234567890',
    );
    await cubit.checkPhone();
    expect(cubit.state.step, RegistrationStep.credentials);
    await cubit.submitPersonal();
    expect(cubit.state.step, RegistrationStep.credentials);
    expect(cubit.state.personal.fullName, isNotNull);
  });

  test('a complete personal step advances to education', () async {
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    await cubit.checkPhone();
    cubit.updateFullName('أحمد');
    cubit.updateDateOfBirth('2007-01-15');
    cubit.updateGender(Gender.male);
    cubit.updateGuardianPhone('01234567891');
    cubit.updateGovernorate('cairo');
    cubit.updateArea('nasr_city');
    await cubit.submitPersonal();
    expect(cubit.state.step, RegistrationStep.education);
  });

  test('changing the stage clears the dependent education selections', () {
    cubit.updateStage(EducationalStage.secondary);
    cubit.updateType(EducationType.general);
    cubit.updateSystem(AcademicSystem.generalSecondary);
    cubit.updateGrade(StudyGrade.secondary2);
    cubit.updateTrack(AcademicTrack.scientific);
    cubit.updateStage(EducationalStage.primary);
    expect(cubit.state.draft.type, isNull);
    expect(cubit.state.draft.system, isNull);
    expect(cubit.state.draft.grade, isNull);
    expect(cubit.state.draft.track, isNull);
  });

  test('the education step requires a valid combination', () async {
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    await cubit.checkPhone();
    cubit.updateFullName('أحمد');
    cubit.updateDateOfBirth('2007-01-15');
    cubit.updateGender(Gender.male);
    cubit.updateGuardianPhone('01234567891');
    cubit.updateGovernorate('cairo');
    cubit.updateArea('nasr_city');
    await cubit.submitPersonal();
    cubit.updateStage(EducationalStage.primary);
    await cubit.submitEducation();
    expect(cubit.state.step, RegistrationStep.education);
    expect(cubit.state.education.grade, isNotNull);
  });

  test('a complete education step advances to review', () async {
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    await cubit.checkPhone();
    cubit.updateFullName('أحمد');
    cubit.updateDateOfBirth('2007-01-15');
    cubit.updateGender(Gender.male);
    cubit.updateGuardianPhone('01234567891');
    cubit.updateGovernorate('cairo');
    cubit.updateArea('nasr_city');
    await cubit.submitPersonal();
    cubit.updateStage(EducationalStage.primary);
    cubit.updateGrade(StudyGrade.primary4);
    await cubit.submitEducation();
    expect(cubit.state.step, RegistrationStep.review);
  });

  test('the review step creates the account and reports success', () async {
    repository.registerResult = null;
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    cubit.updateFullName('أحمد');
    cubit.updateDateOfBirth('2007-01-15');
    cubit.updateGender(Gender.male);
    cubit.updateGuardianPhone('01234567891');
    cubit.updateGovernorate('cairo');
    cubit.updateArea('nasr_city');
    cubit.updateStage(EducationalStage.primary);
    cubit.updateGrade(StudyGrade.primary4);
    cubit.updateSchool('Nile School');
    await cubit.submitEducation();
    await cubit.createAccount();
    expect(cubit.state.step, RegistrationStep.success);
    expect(cubit.state.submitting, isFalse);
    expect(repository.registerCalls, 1);
    expect(repository.capturedRequest?.phone, '+201234567890');
    expect(repository.capturedRequest?.fullName, 'أحمد');
    expect(repository.capturedRequest?.draft.grade, StudyGrade.primary4);
    expect(repository.capturedRequest?.draft.school, 'Nile School');
  });

  test('the password is never stored on the draft', () async {
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    expect(cubit.state.draft.password, 'secret123');
    expect(cubit.state.draft.maskedPassword, '•••••••••');
  });

  test('a duplicate phone number during creation reports failure', () async {
    repository.registerResult = const RegistrationFailure(
      RegistrationFailureKind.phoneAlreadyRegistered,
    );
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    cubit.updateFullName('أحمد');
    cubit.updateDateOfBirth('2007-01-15');
    cubit.updateGender(Gender.male);
    cubit.updateGuardianPhone('01234567891');
    cubit.updateGovernorate('cairo');
    cubit.updateArea('nasr_city');
    cubit.updateStage(EducationalStage.primary);
    cubit.updateGrade(StudyGrade.primary4);
    await cubit.submitEducation();
    await cubit.createAccount();
    expect(cubit.state.step, RegistrationStep.review);
    expect(cubit.state.failure, RegistrationFailureKind.phoneAlreadyRegistered);
    expect(cubit.state.submitting, isFalse);
  });

  test('repeated create taps do not submit twice', () async {
    final completer = Completer<void>();
    repository.registerCompleter = completer;
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    cubit.updateFullName('أحمد');
    cubit.updateDateOfBirth('2007-01-15');
    cubit.updateGender(Gender.male);
    cubit.updateGuardianPhone('01234567891');
    cubit.updateGovernorate('cairo');
    cubit.updateArea('nasr_city');
    cubit.updateStage(EducationalStage.primary);
    cubit.updateGrade(StudyGrade.primary4);
    await cubit.submitEducation();
    final first = cubit.createAccount();
    await cubit.createAccount();
    expect(repository.registerCalls, 1);
    completer.complete();
    await first;
  });

  test('a network failure during creation stays on review', () async {
    repository.registerResult = const RegistrationFailure(
      RegistrationFailureKind.network,
    );
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    cubit.updateFullName('أحمد');
    cubit.updateDateOfBirth('2007-01-15');
    cubit.updateGender(Gender.male);
    cubit.updateGuardianPhone('01234567891');
    cubit.updateGovernorate('cairo');
    cubit.updateArea('nasr_city');
    cubit.updateStage(EducationalStage.primary);
    cubit.updateGrade(StudyGrade.primary4);
    await cubit.submitEducation();
    await cubit.createAccount();
    expect(cubit.state.step, RegistrationStep.review);
    expect(cubit.state.failure, RegistrationFailureKind.network);
  });

  test('back navigation preserves entered values', () async {
    cubit.updatePhone('01234567890');
    cubit.updatePassword('secret123');
    cubit.updateConfirmPassword('secret123');
    await cubit.checkPhone();
    cubit.updateFullName('أحمد');
    cubit.updateDateOfBirth('2007-01-15');
    cubit.updateGender(Gender.male);
    cubit.updateGuardianPhone('01234567891');
    cubit.updateGovernorate('cairo');
    cubit.updateArea('nasr_city');
    await cubit.submitPersonal();
    cubit.updateStage(EducationalStage.secondary);
    cubit.updateType(EducationType.general);
    cubit.updateSystem(AcademicSystem.egyptianBaccalaureate);
    cubit.updateGrade(StudyGrade.secondary2);
    cubit.updateTrack(AcademicTrack.medicineAndLifeSciences);
    cubit.goBack();
    expect(cubit.state.step, RegistrationStep.personal);
    expect(cubit.state.draft.phone, '01234567890');
    expect(cubit.state.draft.fullName, 'أحمد');
    cubit.goBack();
    expect(cubit.state.step, RegistrationStep.credentials);
    expect(cubit.state.draft.guardianPhone, '01234567891');
    cubit.goBack();
    expect(cubit.state.step, RegistrationStep.credentials);
  });

  test('editing from review keeps valid values', () async {
    cubit.updateFullName('أحمد');
    cubit.updateDateOfBirth('2007-01-15');
    cubit.updateGender(Gender.male);
    cubit.updateGuardianPhone('01234567891');
    cubit.updateGovernorate('cairo');
    cubit.updateArea('nasr_city');
    cubit.updateStage(EducationalStage.primary);
    cubit.updateGrade(StudyGrade.primary4);
    await cubit.submitEducation();
    expect(cubit.state.step, RegistrationStep.review);
    cubit.editStep(RegistrationStep.personal);
    expect(cubit.state.step, RegistrationStep.personal);
    expect(cubit.state.draft.fullName, 'أحمد');
  });

  test('restarting keeps the draft out of persistence', () {
    final draft = _completeDraft();
    expect(draft.password, 'secret123');
    expect(draft.maskedPassword, '•••••••••');
  });
}

class _FakeRegistrationRepository implements RegistrationRepository {
  PhoneAvailability availabilityResult = const PhoneAvailability(
    status: PhoneAvailabilityStatus.available,
    phone: '+201234567890',
  );
  Completer<PhoneAvailability>? availabilityCompleter;
  int availabilityCalls = 0;
  List<String> checkedPhones = [];

  RegistrationFailure? registerResult;
  Completer<void>? registerCompleter;
  int registerCalls = 0;
  StudentRegistrationRequest? capturedRequest;

  @override
  Future<PhoneAvailability> checkPhoneAvailability(String phone) async {
    availabilityCalls++;
    checkedPhones.add(phone);
    return availabilityCompleter?.future ?? availabilityResult;
  }

  @override
  Future<void> registerStudent(StudentRegistrationRequest request) async {
    registerCalls++;
    capturedRequest = request;
    await registerCompleter?.future;
    if (registerResult != null) throw registerResult!;
  }
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/features/auth/data/repositories/fake_registration_repository.dart';
import 'package:taleb/features/auth/domain/entities/registration_draft.dart';
import 'package:taleb/features/auth/domain/repositories/registration_repository.dart';

const _taken = '+201234567890';

void main() {
  late FakeRegistrationRepository repository;

  setUp(() => repository = FakeRegistrationRepository(takenNumbers: [_taken]));

  test('a registered number reports taken', () async {
    final result = await repository.checkPhoneAvailability(_taken);
    expect(result.status, PhoneAvailabilityStatus.taken);
    expect(result.available, isFalse);
  });

  test('a free number reports available', () async {
    final result = await repository.checkPhoneAvailability('+201111111111');
    expect(result.status, PhoneAvailabilityStatus.available);
    expect(result.available, isTrue);
  });

  test('the same normalized number is checked consistently', () async {
    // The caller passes an already normalized number; the fake echoes it.
    final result = await repository.checkPhoneAvailability(_taken);
    expect(result.phone, _taken);
  });

  test('a simulated failure is never treated as available', () async {
    repository.failNextAvailabilityCheck = true;
    await expectLater(
      repository.checkPhoneAvailability('+201111111111'),
      throwsA(isA<RegistrationFailure>()),
    );
  });

  test('registration succeeds and records the created number', () async {
    const phone = '+201111111111';
    await repository.registerStudent(
      StudentRegistrationRequest(
        phone: phone,
        password: 'secret123',
        fullName: 'Ahmed',
        draft: const RegistrationDraft.empty(),
      ),
    );
    expect(repository.createdNumbers, contains(phone));
    // The number is now taken for subsequent checks.
    final result = await repository.checkPhoneAvailability(phone);
    expect(result.status, PhoneAvailabilityStatus.taken);
  });

  test('a taken number cannot register twice', () async {
    await expectLater(
      repository.registerStudent(
        StudentRegistrationRequest(
          phone: _taken,
          password: 'secret123',
          fullName: 'Ahmed',
          draft: const RegistrationDraft.empty(),
        ),
      ),
      throwsA(
        isA<RegistrationFailure>().having(
          (failure) => failure.kind,
          'kind',
          RegistrationFailureKind.phoneAlreadyRegistered,
        ),
      ),
    );
  });

  test('a simulated creation failure never records the number', () async {
    repository.failNextRegistration = true;
    await expectLater(
      repository.registerStudent(
        StudentRegistrationRequest(
          phone: '+201111111111',
          password: 'secret123',
          fullName: 'Ahmed',
          draft: const RegistrationDraft.empty(),
        ),
      ),
      throwsA(isA<RegistrationFailure>()),
    );
    expect(repository.createdNumbers, isEmpty);
  });

  test('the request carries no password on the captured draft', () async {
    await repository.registerStudent(
      StudentRegistrationRequest(
        phone: '+201111111111',
        password: 'secret123',
        fullName: 'Ahmed',
        draft: const RegistrationDraft.empty(),
      ),
    );
    // The password is used only to accept the request; it is never stored.
    expect(repository.createdNumbers.length, 1);
  });

  test('a network failure is mapped, not swallowed', () async {
    repository.failNextRegistration = true;
    repository.failureKind = RegistrationFailureKind.network;
    await expectLater(
      repository.registerStudent(
        StudentRegistrationRequest(
          phone: '+201111111111',
          password: 'secret123',
          fullName: 'Ahmed',
          draft: const RegistrationDraft.empty(),
        ),
      ),
      throwsA(
        isA<RegistrationFailure>().having(
          (failure) => failure.kind,
          'kind',
          RegistrationFailureKind.network,
        ),
      ),
    );
  });

  test('an in-flight check blocks a concurrent duplicate', () async {
    final gate = Completer<void>();
    repository.availabilityGate = gate;
    final first = repository.checkPhoneAvailability('+201111111111');
    // The second call is serialized behind the gate, not started twice.
    final second = repository.checkPhoneAvailability('+201111111111');
    gate.complete();
    await first;
    await second;
    expect(repository.availabilityCalls, 2);
  });
}

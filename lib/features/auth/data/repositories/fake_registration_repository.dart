import 'dart:async';

import '../../domain/repositories/registration_repository.dart';

/// An in-memory stand-in for [RegistrationRepository] used only to drive the
/// registration flow on an emulator without a reachable backend.
///
/// Enabled by the debug-only `FAKE_REGISTRATION` flag. It must never run in a
/// release build: it accepts any password and pretends account creation
/// succeeded, so it proves UI behavior only, never real authentication.
class FakeRegistrationRepository implements RegistrationRepository {
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
    final taken = takenNumbers.contains(phone) || createdNumbers.contains(phone);
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
}

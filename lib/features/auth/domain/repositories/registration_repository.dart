import '../entities/registration_draft.dart';

/// The outcome of asking the trusted backend whether a phone number is free.
///
/// [unavailable] means the check itself could not be completed (network,
/// timeout, unexpected response). It is deliberately **not** treated as
/// availability: a caller must never advance a registration because a
/// uniqueness check failed to return.
enum PhoneAvailabilityStatus {
  /// The backend confirmed the number is not registered.
  available,

  /// The backend confirmed the number is already registered.
  taken,

  /// The check could not be completed. Never interpret this as available.
  unavailable,
}

class PhoneAvailability {
  const PhoneAvailability({required this.status, this.phone});

  final PhoneAvailabilityStatus status;

  /// The number the backend checked, in E.164, when it answered.
  final String? phone;

  /// Whether the number may be used to continue registration.
  bool get available => status == PhoneAvailabilityStatus.available;
}

/// Whether the availability check itself failed rather than answered.
bool isPhoneAvailabilityFailure(PhoneAvailability availability) =>
    availability.status == PhoneAvailabilityStatus.unavailable;

/// The student registration payload sent to the authentication provider.
///
/// Contains no password: the password is passed separately to the provider
/// and is never stored on the payload, in a draft, or in a profile row.
class StudentRegistrationRequest {
  const StudentRegistrationRequest({
    required this.phone,
    required this.password,
    required this.fullName,
    required this.draft,
  });

  /// The normalized phone number in E.164 (+20XXXXXXXXXX).
  final String phone;

  /// The plaintext password, held only in memory while the request is in
  /// flight. Never persisted, logged, or written to a profile table.
  final String password;

  final String fullName;

  /// The complete collected draft, used to persist the profile details.
  final RegistrationDraft draft;
}

/// The trusted operations the student registration flow depends on.
///
/// Phone-number uniqueness is enforced by the backend. The availability check
/// is a client convenience that may report [PhoneAvailabilityStatus.taken];
/// it cannot guarantee uniqueness, and the final account-creation operation
/// must reject a duplicate independently.
abstract interface class RegistrationRepository {
  /// Asks the trusted backend whether [phone] (already E.164) is available.
  ///
  /// Returns [PhoneAvailabilityStatus.unavailable] when the check cannot be
  /// completed. The response never reveals anything about an existing
  /// account beyond the fact that the number is registered.
  Future<PhoneAvailability> checkPhoneAvailability(String phone);

  /// Creates the account with the configured authentication provider.
  ///
  /// Throws a [RegistrationFailure] when the provider rejects the request,
  /// including a duplicate phone number, so a caller cannot confuse a failed
  /// creation with success.
  Future<void> registerStudent(StudentRegistrationRequest request);
}

/// Reasons a registration operation can fail, mapped to a localized message
/// by the presentation layer.
enum RegistrationFailureKind {
  phoneAlreadyRegistered,
  network,
  timeout,
  validation,
  authentication,
  profileCreation,
  unexpected,
}

class RegistrationFailure implements Exception {
  const RegistrationFailure(this.kind, {this.cause});

  final RegistrationFailureKind kind;
  final Object? cause;

  @override
  String toString() => 'RegistrationFailure($kind)';
}

import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/features/auth/domain/repositories/registration_repository.dart';

void main() {
  group('PhoneAvailability', () {
    test('available keeps the normalized number', () {
      const availability = PhoneAvailability(
        status: PhoneAvailabilityStatus.available,
        phone: '+201234567890',
      );
      expect(availability.available, isTrue);
    });

    test('taken is not available', () {
      const availability = PhoneAvailability(
        status: PhoneAvailabilityStatus.taken,
        phone: '+201234567890',
      );
      expect(availability.available, isFalse);
    });

    test('a check failure is never treated as availability', () {
      const availability = PhoneAvailability(
        status: PhoneAvailabilityStatus.unavailable,
      );
      expect(availability.available, isFalse);
    });
  });

  group('isPhoneAvailabilityFailure', () {
    test('only an unavailable check is a failure', () {
      expect(
        isPhoneAvailabilityFailure(
          const PhoneAvailability(status: PhoneAvailabilityStatus.unavailable),
        ),
        isTrue,
      );
      expect(
        isPhoneAvailabilityFailure(
          const PhoneAvailability(
            status: PhoneAvailabilityStatus.taken,
            phone: '+201234567890',
          ),
        ),
        isFalse,
      );
    });
  });
}

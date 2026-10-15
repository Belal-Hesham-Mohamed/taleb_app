import 'package:flutter_test/flutter_test.dart';
import 'package:taleb/features/auth/domain/validation/phone_number.dart';

void main() {
  group('normalizePhoneNumber', () {
    test('accepts E.164 input', () {
      expect(normalizePhoneNumber('+201234567890'), '+201234567890');
      expect(normalizePhoneNumber('+20 12 3456 7890'), '+201234567890');
    });

    test('accepts the international 00 prefix', () {
      expect(normalizePhoneNumber('00201234567890'), '+201234567890');
    });

    test('accepts a local number with the trunk zero', () {
      expect(normalizePhoneNumber('01234567890'), '+201234567890');
    });

    test('accepts a bare ten digit mobile number', () {
      expect(normalizePhoneNumber('1234567890'), '+201234567890');
    });

    test('ignores separators', () {
      expect(normalizePhoneNumber('12-3456-7890'), '+201234567890');
      expect(normalizePhoneNumber('(012) 3456 7890'), '+201234567890');
    });

    test('rejects numbers that are not ten digit Egyptian mobiles', () {
      expect(normalizePhoneNumber('12345'), isNull);
      expect(normalizePhoneNumber(''), isNull);
      expect(normalizePhoneNumber('0123456789'), isNull);
      expect(normalizePhoneNumber('2234567890'), isNull);
      expect(normalizePhoneNumber('+15551234567'), isNull);
      expect(normalizePhoneNumber('+20123456789012'), isNull);
    });
  });
}

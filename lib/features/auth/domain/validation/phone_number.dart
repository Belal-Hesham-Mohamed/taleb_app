/// Normalizes an Egyptian mobile number to E.164 (+20XXXXXXXXXX).
///
/// Accepts `+20`, `0020`, a leading trunk `0`, or a bare ten digit mobile
/// number, with any separators. Returns `null` for anything that is not a
/// valid ten digit Egyptian mobile number, so callers must treat `null` as
/// "not usable" rather than guessing a format.
String? normalizePhoneNumber(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  var digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.startsWith('0020')) {
    digits = digits.substring(4);
  } else if (digits.startsWith('20') && digits.length == 12) {
    digits = digits.substring(2);
  } else if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  if (digits.length != 10) return null;
  if (!digits.startsWith('1')) return null;
  return '+20$digits';
}

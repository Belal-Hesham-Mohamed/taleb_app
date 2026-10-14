import 'package:shared_preferences/shared_preferences.dart';

class LocaleRepository {
  static const _key = 'preferred_locale';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<String?> read() => _preferences.getString(_key);
  Future<void> write(String languageCode) =>
      _preferences.setString(_key, languageCode);
}

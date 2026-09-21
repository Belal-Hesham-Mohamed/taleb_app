import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage_keys.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  const SecureStorage({
    required this._storage,
  });

  Future<void> saveAccessToken(String token) async {
    await _storage.write(
      key: SecureStorageKeys.accessToken,
      value: token,
    );
  }

  Future<String?> getAccessToken() async {
    return _storage.read(
      key: SecureStorageKeys.accessToken,
    );
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: SecureStorageKeys.refreshToken,
      value: token,
    );
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(
      key: SecureStorageKeys.refreshToken,
    );
  }

  Future<void> clearTokens() async {
    await _storage.delete(
      key: SecureStorageKeys.accessToken,
    );

    await _storage.delete(
      key: SecureStorageKeys.refreshToken,
    );
  }
}
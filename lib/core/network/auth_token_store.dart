import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores bearer tokens in the platform Keychain / encrypted Android storage.
/// Existing installations are migrated from SharedPreferences on first read.
class AuthTokenStore {
  static const tokenKey = 'ben_auth_token';
  static const _legacyTokenKey = 'ben_auth_token';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<String?> read() async {
    final secureValue = (await _secureStorage.read(key: tokenKey))?.trim();
    if (secureValue != null && secureValue.isNotEmpty) return secureValue;

    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getString(_legacyTokenKey)?.trim();
    if (legacyValue == null || legacyValue.isEmpty) return null;

    // Write the secure copy before deleting the legacy value.
    await _secureStorage.write(key: tokenKey, value: legacyValue);
    await prefs.remove(_legacyTokenKey);
    return legacyValue;
  }

  Future<void> write(String token) async {
    await _secureStorage.write(key: tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenKey);
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenKey);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Durable authentication token storage.
///
/// Keeping persistence behind a tiny abstraction makes auth testable and
/// prevents screens from knowing how the session is stored on-device.
class AuthTokenStore {
  static const tokenKey = 'ben_auth_token';

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(tokenKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> write(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';

class BenUser {
  final int id;
  final String username;
  final String email;
  final int xp;
  final int coins;
  final String bio;
  final String avatarUrl;
  final String bioFont;
  final int bioColor;
  const BenUser({required this.id, required this.username, required this.email, this.xp = 0, this.coins = 0, this.bio = '', this.avatarUrl = '', this.bioFont = 'default', this.bioColor = 0xFFB9F7FF});

  factory BenUser.fromJson(Map<String, dynamic> json) => BenUser(
    id: int.tryParse('${json['id']}') ?? 0,
    username: '${json['username'] ?? ''}',
    email: '${json['email'] ?? ''}',
    xp: int.tryParse('${json['xp'] ?? 0}') ?? 0,
    coins: int.tryParse('${json['coins'] ?? 0}') ?? 0,
    bio: '${json['bio'] ?? ''}',
    avatarUrl: '${json['avatar_url'] ?? ''}',
    bioFont: '${json['bio_font'] ?? 'default'}',
    bioColor: int.tryParse('${json['bio_color'] ?? 0xFFB9F7FF}') ?? 0xFFB9F7FF,
  );

  Map<String, dynamic> toJson() => {'id': id, 'username': username, 'email': email, 'xp': xp, 'coins': coins, 'bio': bio, 'avatar_url': avatarUrl, 'bio_font': bioFont, 'bio_color': bioColor};
}

class AuthService {
  static BenUser? currentUser;
  static const _userKey = 'ben_current_user';
  static const _tokenKey = 'ben_auth_token';
  final ApiClient api;
  const AuthService(this.api);

  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    final token = prefs.getString(_tokenKey);
    if (raw == null || token == null || token.isEmpty) return false;
    try {
      currentUser = BenUser.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      ApiClient.token = token;
      return currentUser!.id > 0;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<void> _saveSession(BenUser user, String? token) async {
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      ApiClient.token = token;
      await prefs.setString(_tokenKey, token);
    }
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<BenUser> register({required String username, required String email, required String password}) async {
    final result = await api.post('auth/register', body: {'username': username, 'email': email, 'password': password});
    final user = BenUser.fromJson(Map<String, dynamic>.from(result['user'] as Map));
    await _saveSession(user, result['token']?.toString());
    return user;
  }

  Future<BenUser> login({required String email, required String password}) async {
    final result = await api.post('auth/login', body: {'email': email, 'password': password});
    final user = BenUser.fromJson(Map<String, dynamic>.from(result['user'] as Map));
    await _saveSession(user, result['token']?.toString());
    return user;
  }

  Future<void> logout() async {
    ApiClient.token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<void> persistCurrentUser() async {
    final user = currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<void> clearSession() async {
    currentUser = null;
    ApiClient.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}

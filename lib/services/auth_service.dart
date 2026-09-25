import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import '../core/network/auth_token_store.dart';

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

  const BenUser({
    required this.id,
    required this.username,
    required this.email,
    this.xp = 0,
    this.coins = 0,
    this.bio = '',
    this.avatarUrl = '',
    this.bioFont = 'default',
    this.bioColor = 0xFFB9F7FF,
  });

  factory BenUser.fromJson(Map<String, dynamic> json) => BenUser(
        id: int.tryParse('${json['id']}') ?? 0,
        username: '${json['username'] ?? ''}',
        email: '${json['email'] ?? ''}',
        xp: int.tryParse('${json['xp'] ?? 0}') ?? 0,
        coins: int.tryParse('${json['coins'] ?? 0}') ?? 0,
        bio: '${json['bio'] ?? ''}',
        avatarUrl: '${json['avatar_url'] ?? ''}',
        bioFont: '${json['bio_font'] ?? 'default'}',
        bioColor: int.tryParse('${json['bio_color'] ?? 0xFFB9F7FF}') ??
            0xFFB9F7FF,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'xp': xp,
        'coins': coins,
        'bio': bio,
        'avatar_url': avatarUrl,
        'bio_font': bioFont,
        'bio_color': bioColor,
      };
}

class AuthService {
  static BenUser? currentUser;
  static const _userKey = 'ben_current_user';

  AuthService(this.api, {AuthTokenStore? tokenStore})
      : _tokenStore = tokenStore ?? AuthTokenStore();

  final ApiClient api;
  final AuthTokenStore _tokenStore;

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    final token = await _tokenStore.read();
    if (raw == null || token == null) return false;

    try {
      currentUser = BenUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      await api.setToken(token);
      final remote = await api.get('auth/me');
      if (remote is! Map || remote['user'] is! Map) {
        await clearSession();
        return false;
      }
      currentUser = BenUser.fromJson(
        Map<String, dynamic>.from(remote['user'] as Map),
      );
      await _persistUser();
      return currentUser!.id > 0;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<BenUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final result = await api.post('auth/register', body: {
      'username': username,
      'email': email,
      'password': password,
    });
    return _acceptAuthResponse(result);
  }

  Future<BenUser> login({
    required String email,
    required String password,
  }) async {
    final result = await api.post('auth/login', body: {
      'email': email,
      'password': password,
    });
    return _acceptAuthResponse(result);
  }

  Future<BenUser> _acceptAuthResponse(dynamic result) async {
    if (result is! Map || result['user'] is! Map) {
      throw const ApiException('Sunucudan geçerli kullanıcı bilgisi alınamadı.');
    }
    final user = BenUser.fromJson(
      Map<String, dynamic>.from(result['user'] as Map),
    );
    final token = result['token']?.toString().trim();
    if (token == null || token.isEmpty) {
      throw const ApiException('Giriş yanıtında oturum anahtarı bulunamadı.');
    }
    await api.setToken(token);
    currentUser = user;
    await _persistUser();
    return user;
  }

  Future<void> logout() async {
    try {
      if (api.currentToken?.isNotEmpty == true) {
        await api.post('auth/logout');
      }
    } catch (_) {
      // Local logout must still complete when the network is unavailable.
    } finally {
      await clearSession();
    }
  }

  Future<void> updateCachedUser(BenUser user) async {
    currentUser = user;
    await _persistUser();
  }

  Future<void> _persistUser() async {
    final user = currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<void> persistCurrentUser() async {
    final user = currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    currentUser = null;
    await api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}

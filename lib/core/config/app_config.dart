import 'package:flutter/foundation.dart';

/// API address can be overridden at build time with BEN_API_URL.
/// Release builds require an explicitly configured HTTPS endpoint.
class AppConfig {
  static const String _configuredApiUrl =
      String.fromEnvironment('BEN_API_URL');

  static final String apiBaseUrl = _configuredApiUrl.trim().isNotEmpty
      ? _configuredApiUrl.trim().replaceFirst(RegExp(r'/+
), '')
      : !kDebugMode
          ? ''
          : defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:8080/api'
              : 'http://127.0.0.1:8080/api';
}

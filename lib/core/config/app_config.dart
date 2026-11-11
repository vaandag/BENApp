import 'package:flutter/foundation.dart';

/// API adresi yerel geliştirmede varsayılan emülatör adresini kullanır.
/// Release derlemelerinde BEN_API_URL mutlaka HTTPS adresiyle verilmelidir.
class AppConfig {
  static const String _configuredApiUrl =
      String.fromEnvironment('BEN_API_URL');

  static final String apiBaseUrl = _configuredApiUrl.trim().isNotEmpty
      ? _configuredApiUrl.trim().replaceFirst(RegExp(r'/+$'), '')
      : kDebugMode
          ? 'http://10.0.2.2:8080/api'
          : '';
}

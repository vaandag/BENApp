/// API adresi derleme sırasında değiştirilebilir:
/// flutter run --dart-define=BEN_API_URL=http://192.168.1.10:8080/api
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'BEN_API_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );
}

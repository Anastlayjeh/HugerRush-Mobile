class AppConfig {
  const AppConfig._();

  /// Configure at runtime:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static Uri apiUri(String path) {
    final sanitizedBase = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$sanitizedBase$normalizedPath');
  }
}

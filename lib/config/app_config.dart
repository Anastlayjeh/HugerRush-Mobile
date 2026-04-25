import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  /// Configure at runtime:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    final configured = _configuredApiBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8000';
    }
  }

  static Uri apiUri(String path) {
    final sanitizedBase = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$sanitizedBase$normalizedPath');
  }
}

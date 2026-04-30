import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  /// Configure at runtime:
  /// flutter run --dart-define=API_BASE_URL=https://api.example.com
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

  /// Optional escape hatch for local tests only.
  static const bool allowInsecureHttp = bool.fromEnvironment(
    'ALLOW_INSECURE_HTTP',
    defaultValue: false,
  );

  static void validate() {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      throw StateError(
        'Invalid API_BASE_URL "$apiBaseUrl". Provide a valid absolute URL.',
      );
    }

    final isInsecure = uri.scheme.toLowerCase() == 'http';
    if (kReleaseMode && isInsecure && !allowInsecureHttp) {
      throw StateError(
        'Release builds require HTTPS API_BASE_URL. '
        'Current value: "$apiBaseUrl".',
      );
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

import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const String productionBaseUrl = 'https://hungerrush.site/api';
  static const String localAndroidBaseUrl = 'http://10.0.2.2:8000/api';
  static const String localHostBaseUrl = 'http://127.0.0.1:8000/api';

  /// Override with:
  /// flutter run --dart-define=API_BASE_URL=https://hungerrush.site/api
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  /// Google OAuth Web client ID used for ID token issuance.
  /// Override with:
  /// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=...
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '103967878021-8jmkg6po14bdoja73gte66blb6e9ube6.apps.googleusercontent.com',
  );

  /// Laravel currently exposes Google auth outside the v1 route prefix.
  static const String googleAuthEndpoint = String.fromEnvironment(
    'GOOGLE_AUTH_ENDPOINT',
    defaultValue: '/auth/google',
  );

  /// Local-development escape hatch only. Release builds should use HTTPS.
  static const bool allowInsecureHttp = bool.fromEnvironment(
    'ALLOW_INSECURE_HTTP',
    defaultValue: false,
  );

  static String get baseUrl {
    final configured = _configuredBaseUrl.trim();
    return _stripTrailingSlash(
      configured.isEmpty ? productionBaseUrl : configured,
    );
  }

  static String get apiBaseUrl => baseUrl;

  static void validate() {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      throw StateError(
        'Invalid API_BASE_URL "$baseUrl". Provide a valid absolute URL.',
      );
    }

    if (kReleaseMode &&
        uri.scheme.toLowerCase() == 'http' &&
        !allowInsecureHttp) {
      throw StateError(
        'Release builds require HTTPS API_BASE_URL. Current value: "$baseUrl".',
      );
    }

    final googleEndpoint = googleAuthEndpoint.trim();
    if (googleEndpoint.isEmpty || !googleEndpoint.startsWith('/')) {
      throw StateError(
        'GOOGLE_AUTH_ENDPOINT must be a non-empty path starting with "/". '
        'Current value: "$googleEndpoint".',
      );
    }
  }

  static Uri apiUri(String path) {
    final trimmedPath = path.trim();
    if (_isAbsoluteHttpUrl(trimmedPath)) {
      return Uri.parse(trimmedPath);
    }

    final normalizedPath = _normalizeEndpointPath(trimmedPath);
    return Uri.parse('$baseUrl$normalizedPath');
  }

  static String resolveMediaUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final baseUri = Uri.parse(baseUrl);
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null &&
        parsed.hasScheme &&
        (parsed.scheme.toLowerCase() == 'http' ||
            parsed.scheme.toLowerCase() == 'https')) {
      return _preferHttpsForProductionHost(parsed).toString();
    }

    if (trimmed.startsWith('//')) {
      return _preferHttpsForProductionHost(
        Uri.parse('${baseUri.scheme}:$trimmed'),
      ).toString();
    }

    final normalizedPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    if (normalizedPath.startsWith('/v1/')) {
      return apiUri(normalizedPath).toString();
    }

    return _preferHttpsForProductionHost(
      _originUri(baseUri).resolve(normalizedPath),
    ).toString();
  }

  static String _normalizeEndpointPath(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    // During the migration to an /api base URL, keep legacy /api/... endpoint
    // paths from accidentally producing /api/api/...
    if (Uri.parse(
          baseUrl,
        ).path.replaceAll(RegExp(r'/+$'), '').endsWith('/api') &&
        normalizedPath.startsWith('/api/')) {
      return normalizedPath.substring(4);
    }

    return normalizedPath;
  }

  static bool _isAbsoluteHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https') &&
        uri.host.isNotEmpty;
  }

  static Uri _originUri(Uri uri) {
    return uri.replace(path: '/', query: null, fragment: null);
  }

  static Uri _preferHttpsForProductionHost(Uri uri) {
    final productionHost = Uri.parse(productionBaseUrl).host;
    if (uri.scheme.toLowerCase() == 'http' && uri.host == productionHost) {
      return uri.replace(scheme: 'https');
    }
    return uri;
  }

  static String _stripTrailingSlash(String value) {
    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}

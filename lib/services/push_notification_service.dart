import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/auth_session.dart';
import 'api_client.dart';
import 'auth_api_service.dart';
import 'auth_session_service.dart';
import 'authenticated_api_client.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FlutterLocalNotificationsPlugin _backgroundLocalNotifications =
      FlutterLocalNotificationsPlugin();
  final AuthSessionService _authSessionService = AuthSessionService();
  late final AuthenticatedApiClient _authenticatedApiClient =
      AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: _authSessionService,
      );

  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isInitialized = false;
  static bool _backgroundNotificationsReady = false;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'hungerrush_notifications',
        'HungerRush Notifications',
        description: 'Order and account notifications from HungerRush',
        importance: Importance.high,
      );

  Future<void> initialize() async {
    if (_isInitialized || !_supportsFirebaseMessaging) {
      return;
    }
    _isInitialized = true;

    try {
      await _requestPermission();
      await _setupLocalNotifications();
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _listenForForegroundMessages();
      _listenForOpenedMessages();
      _listenForTokenRefresh();
      await _handleInitialMessage();
    } catch (error, stackTrace) {
      _debugLog('Failed to initialize push notifications.', error, stackTrace);
    }
  }

  static Future<void> showBackgroundMessage(RemoteMessage message) async {
    if (!_supportsFirebaseMessagingStatic || message.notification != null) {
      return;
    }

    try {
      final title = _messageTitle(message);
      final body = _messageBody(message);
      if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
        return;
      }

      await _setupBackgroundLocalNotifications();
      await _backgroundLocalNotifications.show(
        id: _notificationId(message),
        title: title ?? 'HungerRush',
        body: body ?? '',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.isEmpty ? null : message.data.toString(),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to show background notification.');
        debugPrint('$error');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('Notification permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(settings: initializationSettings);

    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(_androidChannel);
    await androidNotifications?.requestNotificationsPermission();
  }

  static Future<void> _setupBackgroundLocalNotifications() async {
    if (_backgroundNotificationsReady) {
      return;
    }
    _backgroundNotificationsReady = true;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _backgroundLocalNotifications.initialize(
      settings: initializationSettings,
    );

    final androidNotifications = _backgroundLocalNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(_androidChannel);
  }

  void _listenForForegroundMessages() {
    _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen((
      message,
    ) {
      unawaited(_showForegroundNotification(message));
    });
  }

  void _listenForOpenedMessages() {
    _openedMessageSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      if (kDebugMode) {
        debugPrint('Notification opened: ${message.data}');
      }
    });
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null || !kDebugMode) {
      return;
    }
    debugPrint('Notification launched app: ${initialMessage.data}');
  }

  void _listenForTokenRefresh() {
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      unawaited(_registerTokenFromRefresh(token));
    });
  }

  Future<void> registerCurrentDeviceToken({AuthSession? session}) async {
    if (!_supportsFirebaseMessaging) {
      return;
    }

    try {
      final activeSession = session ?? await _authSessionService.readSession();
      if (activeSession == null || activeSession.token.trim().isEmpty) {
        return;
      }

      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        _debugLog('FCM token is unavailable.');
        return;
      }

      await _registerToken(session: activeSession, token: token);
    } catch (error, stackTrace) {
      _debugLog('Failed to register FCM token.', error, stackTrace);
    }
  }

  Future<void> deactivateCurrentDeviceToken({AuthSession? session}) async {
    if (!_supportsFirebaseMessaging) {
      return;
    }

    try {
      final activeSession = session ?? await _authSessionService.readSession();
      if (activeSession == null || activeSession.token.trim().isEmpty) {
        return;
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final result = await _authenticatedApiClient.request(
        session: activeSession,
        method: 'POST',
        endpoint: '/v1/device-tokens/deactivate',
        body: <String, dynamic>{'token': token},
        timeout: const Duration(seconds: 10),
      );
      if (result.response.statusCode < 200 ||
          result.response.statusCode >= 300) {
        final payload = ApiClient.decodeMap(result.response.body);
        _debugLog(
          ApiClient.errorMessageForStatus(
            result.response.statusCode,
            payload,
            fallback: 'Failed to deactivate FCM token.',
          ),
        );
      }
    } catch (error, stackTrace) {
      _debugLog('Failed to deactivate FCM token.', error, stackTrace);
    }
  }

  Future<void> _registerTokenFromRefresh(String token) async {
    try {
      final session = await _authSessionService.readSession();
      if (session == null || session.token.trim().isEmpty) {
        return;
      }
      await _registerToken(session: session, token: token);
    } catch (error, stackTrace) {
      _debugLog('Failed to register refreshed FCM token.', error, stackTrace);
    }
  }

  Future<void> _registerToken({
    required AuthSession session,
    required String token,
  }) async {
    final platform = _platformName;
    if (platform == null) {
      return;
    }

    final result = await _authenticatedApiClient.request(
      session: session,
      method: 'POST',
      endpoint: '/v1/device-tokens',
      body: <String, dynamic>{
        'token': token,
        'platform': platform,
        'device_name': platform,
      },
      timeout: const Duration(seconds: 10),
    );

    if (result.response.statusCode < 200 || result.response.statusCode >= 300) {
      final payload = ApiClient.decodeMap(result.response.body);
      _debugLog(
        ApiClient.errorMessageForStatus(
          result.response.statusCode,
          payload,
          fallback: 'Failed to register FCM token.',
        ),
      );
      return;
    }

    _debugLog('FCM token registered.');
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = _messageTitle(message);
    final body = _messageBody(message);
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    try {
      await _localNotifications.show(
        id: _notificationId(message),
        title: title ?? 'HungerRush',
        body: body ?? '',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.isEmpty ? null : message.data.toString(),
      );
    } catch (error, stackTrace) {
      _debugLog('Failed to show foreground notification.', error, stackTrace);
    }
  }

  static int _notificationId(RemoteMessage message) {
    final source = message.messageId ?? DateTime.now().microsecondsSinceEpoch;
    return source.hashCode & 0x7fffffff;
  }

  static String? _messageTitle(RemoteMessage message) {
    return _firstNonEmptyString(<Object?>[
      message.notification?.title,
      message.data['title'],
      message.data['notification_title'],
      message.data['subject'],
    ]);
  }

  static String? _messageBody(RemoteMessage message) {
    return _firstNonEmptyString(<Object?>[
      message.notification?.body,
      message.data['body'],
      message.data['message'],
      message.data['notification_body'],
      message.data['text'],
    ]);
  }

  static String? _firstNonEmptyString(Iterable<Object?> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  bool get _supportsFirebaseMessaging {
    return _supportsFirebaseMessagingStatic;
  }

  static bool get _supportsFirebaseMessagingStatic {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  String? get _platformName {
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isMacOS) {
      return 'macos';
    }
    return null;
  }

  void _debugLog(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(message);
    if (error != null) {
      debugPrint('$error');
    }
    if (stackTrace != null) {
      debugPrint('$stackTrace');
    }
  }
}

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Handling background message: ${message.messageId}');
}

class InAppNotificationPayload {
  final String title;
  final String body;
  final String type; // 'friend_request', 'friend_accepted', 'task_shared', etc.
  final Map<String, dynamic> data;

  const InAppNotificationPayload({
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
  });
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _initialized = false;
  String? _currentToken;

  final StreamController<InAppNotificationPayload> _notificationStreamController =
      StreamController<InAppNotificationPayload>.broadcast();

  Stream<InAppNotificationPayload> get onInAppNotification =>
      _notificationStreamController.stream;

  void triggerInAppNotification(InAppNotificationPayload payload) {
    if (!_notificationStreamController.isClosed) {
      _notificationStreamController.add(payload);
    }
  }

  Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      debugPrint('[FCM] Error saving token locally: $e');
    }
  }

  Future<String?> getSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        return;
      }

      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      _currentToken ??= await getSavedToken();

      // Listen for registration token updates
      messaging.onRegistered.listen((token) {
        debugPrint('[FCM] Registered token: $token');
        _currentToken = token;
        _saveTokenLocally(token);
        _syncTokenToServer(token);
      });

      messaging.onUnregistered.listen((token) {
        debugPrint('[FCM] Unregistered token: $token');
        if (_currentToken == token) _currentToken = null;
      });

      // Request permission (required for iOS & Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        try {
          await messaging.register();
          // ignore: deprecated_member_use
          final token = await messaging.getToken();
          if (token != null) {
            _currentToken = token;
            await _saveTokenLocally(token);
            await _syncTokenToServer(token);
          }
        } catch (e) {
          debugPrint('[FCM] Error getting token during init: $e');
        }

        // Listen for foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('[FCM] Foreground notification: ${message.notification?.title}');
          final title = message.notification?.title ?? message.data['title']?.toString() ?? 'TodoCat Notification';
          final body = message.notification?.body ?? message.data['body']?.toString() ?? '';
          final type = message.data['type']?.toString() ?? 'general';

          triggerInAppNotification(InAppNotificationPayload(
            title: title,
            body: body,
            type: type,
            data: message.data,
          ));
        });

        // Listen for user tapping notification from background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('[FCM] Notification opened app: ${message.data}');
          final title = message.notification?.title ?? message.data['title']?.toString() ?? '';
          final body = message.notification?.body ?? message.data['body']?.toString() ?? '';
          final type = message.data['type']?.toString() ?? 'general';

          triggerInAppNotification(InAppNotificationPayload(
            title: title,
            body: body,
            type: type,
            data: message.data,
          ));
        });

        // Check if app was launched via notification click from terminated state
        final initial = await messaging.getInitialMessage();
        if (initial != null) {
          final title = initial.notification?.title ?? initial.data['title']?.toString() ?? '';
          final body = initial.notification?.body ?? initial.data['body']?.toString() ?? '';
          final type = initial.data['type']?.toString() ?? 'general';

          triggerInAppNotification(InAppNotificationPayload(
            title: title,
            body: body,
            type: type,
            data: initial.data,
          ));
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  Future<void> syncCurrentToken() async {
    try {
      if (kIsWeb) return;
      _currentToken ??= await getSavedToken();

      if (_currentToken == null) {
        try {
          // ignore: deprecated_member_use
          _currentToken = await FirebaseMessaging.instance.getToken();
          if (_currentToken != null) {
            await _saveTokenLocally(_currentToken!);
          }
        } catch (_) {}
      }

      if (_currentToken != null) {
        await _syncTokenToServer(_currentToken!);
      } else {
        await FirebaseMessaging.instance.register();
        // ignore: deprecated_member_use
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          _currentToken = token;
          await _saveTokenLocally(token);
          await _syncTokenToServer(token);
        }
      }
    } catch (e) {
      debugPrint('[FCM] syncCurrentToken error: $e');
    }
  }

  Future<void> _syncTokenToServer(String token) async {
    try {
      final isLoggedIn = await ApiService().isLoggedIn();
      if (isLoggedIn) {
        await ApiService().registerFcmToken(token);
        debugPrint('[FCM] Successfully registered token on server');
      } else {
        debugPrint('[FCM] User not logged in, token saved locally for later sync');
      }
    } catch (e) {
      debugPrint('[FCM] Error registering token on server: $e');
    }
  }
}

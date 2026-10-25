import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Handling background message: ${message.messageId}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _initialized = false;
  String? _currentToken;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        return;
      }

      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Listen for registration token updates
      messaging.onRegistered.listen((token) {
        debugPrint('[FCM] Registered token: $token');
        _currentToken = token;
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
        await messaging.register();

        // Listen for foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('[FCM] Foreground notification: ${message.notification?.title}');
        });
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }

  Future<void> syncCurrentToken() async {
    try {
      if (kIsWeb) return;
      if (_currentToken != null) {
        await _syncTokenToServer(_currentToken!);
      } else {
        await FirebaseMessaging.instance.register();
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
      }
    } catch (e) {
      debugPrint('[FCM] Error registering token on server: $e');
    }
  }
}

import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String baseUrl =
      kIsWeb ? 'http://localhost:3000' : 'https://to-do-cat.vercel.app';

  // Web Application Client ID for Google Sign-In serverClientId (ID Token audience)
  static const String googleServerClientId =
      '17924355632-um8arel8s3b3i714rsi0ciaspcjhlif9.apps.googleusercontent.com';

  // Auth endpoints
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String googleAuth = '$baseUrl/api/auth/google';
  static const String me = '$baseUrl/api/auth/me';
  static const String refresh = '$baseUrl/api/auth/refresh';
  static const String logout = '$baseUrl/api/auth/logout';
  static const String forgotPassword = '$baseUrl/api/auth/forgot-password';
  static const String resetPassword = '$baseUrl/api/auth/reset-password';

  // Task endpoints
  static const String tasks = '$baseUrl/api/tasks';
  static String taskById(String id) => '$baseUrl/api/tasks/$id';
  static String taskMeow(String id) => '$baseUrl/api/tasks/$id/meow';

  // Categories endpoint
  static const String categories = '$baseUrl/api/categories';

  // Analytics endpoint
  static const String analytics = '$baseUrl/api/analytics';

  // FCM Token endpoint
  static const String fcmToken = '$baseUrl/api/user/fcm-token';

  // Friend endpoints
  static const String friends = '$baseUrl/api/friends';
  static const String friendsSearch = '$baseUrl/api/friends/search';
  static String friendById(String id) => '$baseUrl/api/friends/$id';
}

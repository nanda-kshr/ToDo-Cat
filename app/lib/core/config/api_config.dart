class ApiConfig {
  static const String baseUrl = 'https://todocat.instaroid.page';

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

  // Task endpoints
  static const String tasks = '$baseUrl/api/tasks';
  static String taskById(String id) => '$baseUrl/api/tasks/$id';

  // Analytics endpoint
  static const String analytics = '$baseUrl/api/analytics';

  // FCM Token endpoint
  static const String fcmToken = '$baseUrl/api/user/fcm-token';
}

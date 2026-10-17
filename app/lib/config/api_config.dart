class ApiConfig {
  static const String baseUrl = 'https://to-do-cat.vercel.app';

  static const String googleClientId =
      '17924355632-ng13bunirja9pvc8aicsaf6nl8q314i5.apps.googleusercontent.com';

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
}

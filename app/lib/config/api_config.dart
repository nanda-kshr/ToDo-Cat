class ApiConfig {
  static const String baseUrl = 'https://to-do-cat.vercel.app';

  // Auth endpoints
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String me = '$baseUrl/api/auth/me';
  static const String refresh = '$baseUrl/api/auth/refresh';
  static const String logout = '$baseUrl/api/auth/logout';

  // Task endpoints
  static const String tasks = '$baseUrl/api/tasks';
  static String taskById(String id) => '$baseUrl/api/tasks/$id';
}

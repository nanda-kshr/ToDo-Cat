import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/config/api_config.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/analytics.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, [this.statusCode = 500]);

  @override
  String toString() => message;
}

class PaginatedTasks {
  final List<Task> tasks;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedTasks({
    required this.tasks,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  static const String _tokenKey = 'todocat_access_token';
  static const String _refreshTokenKey = 'todocat_refresh_token';

  Completer<bool>? _refreshCompleter;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> saveToken(String token) => saveTokens(accessToken: token);

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<void> clearToken() => clearTokens();

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Automatically refreshes the expired access token using the stored refresh token.
  /// Deduplicates parallel refresh calls with a Completer.
  Future<bool> _refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await clearTokens();
        _refreshCompleter!.complete(false);
        return false;
      }

      final response = await _client.post(
        Uri.parse(ApiConfig.refresh),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final newAccess = data['accessToken'] as String?;
        final newRefresh = (data['refreshToken'] as String?) ?? refreshToken;
        if (newAccess != null && newAccess.isNotEmpty) {
          await saveTokens(accessToken: newAccess, refreshToken: newRefresh);
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      // If refresh failed (token expired/revoked), clear stored credentials
      await clearTokens();
      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Wraps authenticated requests to automatically retry once after refreshing an expired token.
  Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) makeRequest,
  ) async {
    final headers = await _getHeaders();
    var response = await makeRequest(headers);

    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        final retryHeaders = await _getHeaders();
        response = await makeRequest(retryHeaders);
      }
    }

    return response;
  }

  // --- Auth API ---

  Future<User> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.login),
        headers: await _getHeaders(),
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data['accessToken'] != null) {
          await saveTokens(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
          );
        }
        return User.fromJson(data['user']);
      } else {
        throw ApiException(
          data['message'] ?? 'Login failed',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error during login: $e');
    }
  }

  Future<User> register(String email, String password, {String? name}) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.register),
        headers: await _getHeaders(),
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data['accessToken'] != null) {
          await saveTokens(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
          );
        }
        return User.fromJson(data['user']);
      } else {
        throw ApiException(
          data['message'] ?? 'Registration failed',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error during registration: $e');
    }
  }

  Future<User> getMe() async {
    try {
      final response = await _authenticatedRequest(
        (headers) => _client.get(Uri.parse(ApiConfig.me), headers: headers),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return User.fromJson(data['user']);
      } else {
        if (response.statusCode == 401) {
          await clearTokens();
        }
        throw ApiException(
          data['message'] ?? 'Unauthorized',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch user profile: $e');
    }
  }

  bool _googleInitialized = false;

  Future<void> _initGoogleSignIn() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: ApiConfig.googleServerClientId,
      );
      _googleInitialized = true;
    }
  }

  Future<User> loginWithGoogle() async {
    try {
      await _initGoogleSignIn();
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();
      final String? idToken = account.authentication.idToken;

      final response = await _client.post(
        Uri.parse(ApiConfig.googleAuth),
        headers: await _getHeaders(),
        body: jsonEncode({
          'idToken': ?idToken,
          'email': account.email,
          'name': account.displayName,
          'googleId': account.id,
          'avatar': account.photoUrl,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data['accessToken'] != null) {
          await saveTokens(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
          );
        }
        return User.fromJson(data['user']);
      } else {
        throw ApiException(
          data['message'] ?? 'Google sign-in failed',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is GoogleSignInException) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          throw ApiException('Sign-in was cancelled');
        }
        throw ApiException(e.description ?? 'Google sign-in failed: ${e.code}');
      }
      throw ApiException('Google sign-in error: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _client.post(
        Uri.parse(ApiConfig.logout),
        headers: await _getHeaders(),
      );
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await clearTokens();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  // --- Tasks API ---

  Future<PaginatedTasks> fetchTasks({int page = 1, int limit = 50}) async {
    try {
      final baseUri = Uri.parse(ApiConfig.tasks);
      final uri = baseUri.replace(
        queryParameters: {
          ...baseUri.queryParameters,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      final response = await _authenticatedRequest(
        (headers) => _client.get(uri, headers: headers),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> list = data['tasks'] ?? [];
        final tasks = list.map((json) => Task.fromJson(json)).toList();
        final pagination = data['pagination'] as Map<String, dynamic>?;
        return PaginatedTasks(
          tasks: tasks,
          page: pagination?['page'] as int? ?? page,
          limit: pagination?['limit'] as int? ?? limit,
          total: pagination?['total'] as int? ?? tasks.length,
          totalPages: pagination?['totalPages'] as int? ?? 1,
        );
      } else {
        throw ApiException(
          data['message'] ?? 'Failed to load tasks',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error fetching tasks: $e');
    }
  }

  Future<Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
    String category = 'General',
  }) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => _client.post(
          Uri.parse(ApiConfig.tasks),
          headers: headers,
          body: jsonEncode({
            'title': title.trim(),
            if (description != null) 'description': description.trim(),
            if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
            'priority': priority,
            'category': category.trim().isNotEmpty ? category.trim() : 'General',
          }),
        ),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Task.fromJson(data['task']);
      } else {
        throw ApiException(
          data['message'] ?? 'Failed to create task',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error creating task: $e');
    }
  }

  Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    bool? completed,
    DateTime? dueDate,
    String? priority,
    String? category,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title.trim();
      if (description != null) body['description'] = description.trim();
      if (completed != null) body['completed'] = completed;
      if (dueDate != null) {
        body['dueDate'] = dueDate.toIso8601String();
      }
      if (priority != null) body['priority'] = priority;
      if (category != null) body['category'] = category.trim();

      final response = await _authenticatedRequest(
        (headers) => _client.patch(
          Uri.parse(ApiConfig.taskById(id)),
          headers: headers,
          body: jsonEncode(body),
        ),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Task.fromJson(data['task']);
      } else {
        throw ApiException(
          data['message'] ?? 'Failed to update task',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error updating task: $e');
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => _client.delete(
          Uri.parse(ApiConfig.taskById(id)),
          headers: headers,
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Failed to delete task',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error deleting task: $e');
    }
  }

  Future<Task> toggleTask(Task task) async {
    return updateTask(task.id, completed: !task.completed);
  }

  // --- Analytics API ---

  Future<TaskAnalytics> fetchAnalytics({
    String? period,
    String? from,
    String? to,
    String? dateField,
  }) async {
    try {
      final baseUri = Uri.parse(ApiConfig.analytics);
      final queryParams = <String, String>{};
      if (period != null && period.isNotEmpty) queryParams['period'] = period;
      if (from != null && from.isNotEmpty) queryParams['from'] = from;
      if (to != null && to.isNotEmpty) queryParams['to'] = to;
      if (dateField != null && dateField.isNotEmpty) queryParams['dateField'] = dateField;

      final uri = queryParams.isEmpty
          ? baseUri
          : baseUri.replace(queryParameters: queryParams);

      final response = await _authenticatedRequest(
        (headers) => _client.get(uri, headers: headers),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return TaskAnalytics.fromJson(data as Map<String, dynamic>);
      } else {
        throw ApiException(
          data['message'] ?? 'Failed to load analytics',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error fetching analytics: $e');
    }
  }
}

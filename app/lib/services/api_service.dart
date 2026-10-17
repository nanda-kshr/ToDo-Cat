import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/task.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, [this.statusCode = 500]);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

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

      final response = await http.post(
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
      final response = await http.post(
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
      final response = await http.post(
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
        (headers) => http.get(Uri.parse(ApiConfig.me), headers: headers),
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
        serverClientId: ApiConfig.googleClientId,
        clientId: ApiConfig.googleClientId,
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

      final response = await http.post(
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
      await http.post(
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

  Future<List<Task>> fetchTasks() async {
    try {
      final response = await _authenticatedRequest(
        (headers) => http.get(Uri.parse(ApiConfig.tasks), headers: headers),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> list = data['tasks'] ?? [];
        return list.map((json) => Task.fromJson(json)).toList();
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
        (headers) => http.post(
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
        (headers) => http.patch(
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
        (headers) => http.delete(
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
}

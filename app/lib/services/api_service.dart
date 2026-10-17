import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

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
          await saveToken(data['accessToken']);
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
          await saveToken(data['accessToken']);
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
      final response = await http.get(
        Uri.parse(ApiConfig.me),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return User.fromJson(data['user']);
      } else {
        if (response.statusCode == 401) {
          await clearToken();
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

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse(ApiConfig.logout),
        headers: await _getHeaders(),
      );
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await clearToken();
    }
  }

  // --- Tasks API ---

  Future<List<Task>> fetchTasks() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.tasks),
        headers: await _getHeaders(),
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
      final response = await http.post(
        Uri.parse(ApiConfig.tasks),
        headers: await _getHeaders(),
        body: jsonEncode({
          'title': title.trim(),
          if (description != null) 'description': description.trim(),
          if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
          'priority': priority,
          'category': category.trim().isNotEmpty ? category.trim() : 'General',
        }),
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

      final response = await http.patch(
        Uri.parse(ApiConfig.taskById(id)),
        headers: await _getHeaders(),
        body: jsonEncode(body),
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
      final response = await http.delete(
        Uri.parse(ApiConfig.taskById(id)),
        headers: await _getHeaders(),
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

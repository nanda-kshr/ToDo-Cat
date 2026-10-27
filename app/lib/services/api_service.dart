import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/config/api_config.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/analytics.dart';
import '../models/friend.dart';
import '../models/category.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(String rawMessage, [this.statusCode = 500])
      : message = _sanitize(rawMessage);

  static final RegExp _technicalPattern = RegExp(
    r'(SocketException|ClientException|MongoServer|ECONNREFUSED|ETIMEDOUT|ENOTFOUND|Traceback|errno\s*=|SyntaxError|FormatException|TypeError|PlatformException|HandshakeException|Failed host lookup|OS Error)',
    caseSensitive: false,
  );

  static String _sanitize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'An unexpected error occurred.';
    if (_technicalPattern.hasMatch(trimmed)) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    return trimmed;
  }

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

  /// Checks if the JWT access token is expired or within [thresholdSeconds] of expiring.
  bool _isTokenExpiringSoon(String token, [int thresholdSeconds = 90]) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadString);
      final exp = payload['exp'];
      if (exp is int) {
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final threshold = DateTime.now().add(Duration(seconds: thresholdSeconds));
        return expiryDate.isBefore(threshold);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Automatically refreshes the expired access token using the stored refresh token.
  /// Deduplicates parallel refresh calls with a single-flight Completer.
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

      // ONLY clear tokens if the server explicitly rejected the refresh token (401 or 403)
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[ApiService] Session revoked or expired by server (${response.statusCode}). Clearing credentials.');
        await clearTokens();
      } else {
        debugPrint('[ApiService] Token refresh returned status ${response.statusCode}. Retaining session tokens.');
      }

      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      // Network drop / socket exception -> do NOT clear tokens!
      debugPrint('[ApiService] Network error during token refresh: $e. Retaining session tokens.');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Wraps authenticated requests to:
  /// 1. Proactively refresh if the access token is expiring within 90s
  /// 2. Reactively retry once with single-flight mutex if the server still returns 401
  Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) makeRequest,
  ) async {
    // 1. Proactive pre-flight refresh
    final currentToken = await getToken();
    if (currentToken != null && _isTokenExpiringSoon(currentToken)) {
      await _refreshAccessToken();
    }

    final headers = await _getHeaders();
    var response = await makeRequest(headers);

    // 2. Reactive retry on 401
    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        final retryHeaders = await _getHeaders();
        response = await makeRequest(retryHeaders);
      }
    }

    return response;
  }

  static final RegExp _technicalLogRegex = RegExp(
    r'(SocketException|ClientException|MongoServer|ECONNREFUSED|ETIMEDOUT|ENOTFOUND|Traceback|errno\s*=|SyntaxError|FormatException|TypeError|PlatformException|HandshakeException|Failed host lookup|OS Error)',
    caseSensitive: false,
  );

  static Map<String, dynamic>? _parseJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  static ApiException _handleResponseError(http.Response response, String defaultMessage) {
    final data = _parseJson(response.body);
    final serverMessage = data?['message'] as String?;
    if (serverMessage != null &&
        serverMessage.trim().isNotEmpty &&
        !_technicalLogRegex.hasMatch(serverMessage)) {
      return ApiException(serverMessage.trim(), response.statusCode);
    }
    if (response.statusCode >= 500) {
      return ApiException('Server is temporarily unavailable. Please try again later.', response.statusCode);
    }
    if (response.statusCode == 404) {
      return ApiException('Requested resource not found.', response.statusCode);
    }
    if (response.statusCode == 429) {
      return ApiException('Too many requests. Please try again later.', response.statusCode);
    }
    if (response.statusCode == 401) {
      return ApiException('Unauthorized. Please log in again.', response.statusCode);
    }
    if (response.statusCode == 403) {
      return ApiException('Access denied.', response.statusCode);
    }
    return ApiException(defaultMessage, response.statusCode);
  }

  static ApiException _handleNetworkError(
    dynamic e, [
    String fallback = 'Unable to connect to server. Please check your internet connection.',
  ]) {
    if (e is ApiException) return e;
    debugPrint('[ApiService] Network/API Error: $e');
    return ApiException(fallback);
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

      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        if (data['accessToken'] != null) {
          await saveTokens(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
          );
        }
        return User.fromJson(data['user']);
      } else {
        throw _handleResponseError(response, 'Login failed');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to connect to server. Please check your internet connection.');
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

      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        if (data['accessToken'] != null) {
          await saveTokens(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
          );
        }
        return User.fromJson(data['user']);
      } else {
        throw _handleResponseError(response, 'Registration failed');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to connect to server. Please check your internet connection.');
    }
  }

  Future<User> getMe() async {
    try {
      final response = await _authenticatedRequest(
        (headers) => _client.get(Uri.parse(ApiConfig.me), headers: headers),
      );

      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        return User.fromJson(data['user']);
      } else {
        throw _handleResponseError(response, 'Failed to fetch user profile');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to connect to server. Please check your internet connection.');
    }
  }

  Future<User> updateProfile({String? name, bool? isProfilePublic}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (isProfilePublic != null) body['isProfilePublic'] = isProfilePublic;

      final response = await _authenticatedRequest(
        (headers) => _client.patch(
          Uri.parse(ApiConfig.me),
          headers: headers,
          body: jsonEncode(body),
        ),
      );

      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        return User.fromJson(data['user']);
      } else {
        throw _handleResponseError(response, 'Failed to update profile');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to connect to server. Please check your internet connection.');
    }
  }

  bool _googleInitialized = false;

  Future<void> _initGoogleSignIn() async {
    if (_googleInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: ApiConfig.googleServerClientId,
      );
      _googleInitialized = true;
    } catch (e) {
      // Already initialized (can happen on web with hot reload)
      _googleInitialized = true;
    }
  }

  Future<User> loginWithGoogle() async {
    try {
      await _initGoogleSignIn();
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();
      final String? idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw ApiException('Google sign-in could not retrieve ID token. Please try again.');
      }

      final response = await _client.post(
        Uri.parse(ApiConfig.googleAuth),
        headers: await _getHeaders(),
        body: jsonEncode({
          'idToken': idToken,
          'email': account.email,
          'name': account.displayName,
          'googleId': account.id,
          'avatar': account.photoUrl,
        }),
      );

      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        if (data['accessToken'] != null) {
          await saveTokens(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
          );
        }
        return User.fromJson(data['user']);
      } else {
        throw _handleResponseError(response, 'Google sign-in failed');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is GoogleSignInException) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          throw ApiException('Sign-in was cancelled');
        }
        throw ApiException('Google sign-in failed. Please try again.');
      }
      throw _handleNetworkError(e, 'Unable to sign in with Google. Please check your internet connection.');
    }
  }

  Future<void> logout() async {
    final headers = await _getHeaders();
    final refreshToken = await getRefreshToken();

    // Clear tokens immediately for instant local logout
    await clearTokens();

    // Perform remote logout and Google SignOut asynchronously in the background
    unawaited(() async {
      try {
        final body = <String, dynamic>{};
        if (refreshToken != null) body['refreshToken'] = refreshToken;

        await _client
            .post(
              Uri.parse(ApiConfig.logout),
              headers: headers,
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 2));
      } catch (_) {}

      try {
        await GoogleSignIn.instance
            .signOut()
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
    }());
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

      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
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
        throw _handleResponseError(response, 'Failed to load tasks');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to connect to server. Please check your internet connection.');
    }
  }

  Future<Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    bool hasTime = false,
    String recurrence = 'none',
    String priority = 'medium',
    String category = 'General',
    List<String>? sharedWith,
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
            'hasTime': hasTime,
            'recurrence': recurrence,
            'priority': priority,
            'category': category.trim().isNotEmpty ? category.trim() : 'General',
            if (sharedWith != null && sharedWith.isNotEmpty) 'sharedWith': sharedWith,
          }),
        ),
      );

      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        return Task.fromJson(data['task']);
      } else {
        throw _handleResponseError(response, 'Failed to create task');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to create task. Please check your internet connection.');
    }
  }

  Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    bool? completed,
    bool? deleted,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? hasTime,
    String? recurrence,
    String? priority,
    String? category,
    List<String>? sharedWith,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title.trim();
      if (description != null) body['description'] = description.trim();
      if (completed != null) body['completed'] = completed;
      if (deleted != null) body['deleted'] = deleted;
      if (dueDate != null) {
        body['dueDate'] = dueDate.toIso8601String();
      } else if (clearDueDate) {
        body['dueDate'] = null;
      }
      if (hasTime != null) body['hasTime'] = hasTime;
      if (recurrence != null) body['recurrence'] = recurrence;
      if (priority != null) body['priority'] = priority;
      if (category != null) body['category'] = category.trim();
      if (sharedWith != null) body['sharedWith'] = sharedWith;

      final response = await _authenticatedRequest(
        (headers) => _client.patch(
          Uri.parse(ApiConfig.taskById(id)),
          headers: headers,
          body: jsonEncode(body),
        ),
      );

      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        return Task.fromJson(data['task']);
      } else {
        throw _handleResponseError(response, 'Failed to update task');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to update task. Please check your internet connection.');
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
        throw _handleResponseError(response, 'Failed to delete task');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to delete task. Please check your internet connection.');
    }
  }

  Future<Task> toggleTask(Task task) async {
    return updateTask(task.id, completed: !task.completed);
  }

  Future<void> sendMeow(String taskId, String targetUserId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => _client.post(
          Uri.parse(ApiConfig.taskMeow(taskId)),
          headers: headers,
          body: jsonEncode({'targetUserId': targetUserId}),
        ),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw _handleResponseError(response, 'Failed to send Meow');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to send Meow. Please check your internet connection.');
    }
  }

  // --- Analytics API ---

  Future<TaskAnalytics> fetchAnalytics({
    String? period,
    String? from,
    String? to,
    String? dateField,
    String? friendId,
  }) async {
    try {
      final baseUri = Uri.parse(ApiConfig.analytics);
      final queryParams = <String, String>{};
      if (period != null && period.isNotEmpty) queryParams['period'] = period;
      if (from != null && from.isNotEmpty) queryParams['from'] = from;
      if (to != null && to.isNotEmpty) queryParams['to'] = to;
      if (dateField != null && dateField.isNotEmpty) queryParams['dateField'] = dateField;
      if (friendId != null && friendId.isNotEmpty) queryParams['friendId'] = friendId;

      final uri = queryParams.isEmpty
          ? baseUri
          : baseUri.replace(queryParameters: queryParams);

      final response = await _authenticatedRequest(
        (headers) => _client.get(uri, headers: headers),
      );

      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        return TaskAnalytics.fromJson(data);
      } else {
        throw _handleResponseError(response, 'Failed to load analytics');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to load analytics. Please check your internet connection.');
    }
  }

  Future<void> registerFcmToken(String token) async {
    try {
      await _authenticatedRequest(
        (headers) => _client.post(
          Uri.parse(ApiConfig.fcmToken),
          headers: headers,
          body: jsonEncode({'token': token}),
        ),
      );
    } catch (e) {
      // Non-blocking error
      debugPrint('[ApiService] registerFcmToken error: $e');
    }
  }

  Future<void> unregisterFcmToken(String token) async {
    try {
      await _authenticatedRequest(
        (headers) => _client.delete(
          Uri.parse(ApiConfig.fcmToken),
          headers: headers,
          body: jsonEncode({'token': token}),
        ),
      );
    } catch (e) {
      debugPrint('[ApiService] unregisterFcmToken error: $e');
    }
  }

  Future<FriendsData> fetchFriends({int? page, int? limit, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = queryParams.isEmpty
          ? Uri.parse(ApiConfig.friends)
          : Uri.parse(ApiConfig.friends).replace(queryParameters: queryParams);

      final response = await _authenticatedRequest(
        (headers) => _client.get(uri, headers: headers),
      );
      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        return FriendsData.fromJson(data);
      } else {
        throw _handleResponseError(response, 'Failed to load friends');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to load friends. Please check your internet connection.');
    }
  }

  Future<List<FriendUser>> searchFriends(String email) async {
    try {
      final uri = Uri.parse(ApiConfig.friendsSearch).replace(
        queryParameters: {'email': email.trim()},
      );
      final response = await _authenticatedRequest(
        (headers) => _client.get(uri, headers: headers),
      );
      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        final list = (data['users'] as List? ?? []);
        return list.map((e) => FriendUser.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw _handleResponseError(response, 'Failed to search users');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to search users. Please check your internet connection.');
    }
  }

  Future<void> sendFriendRequest(String email) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => _client.post(
          Uri.parse(ApiConfig.friends),
          headers: headers,
          body: jsonEncode({'email': email.trim()}),
        ),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw _handleResponseError(response, 'Failed to send friend request');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to send friend request. Please check your internet connection.');
    }
  }

  Future<void> respondFriendRequest(String friendshipId, String action) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => _client.patch(
          Uri.parse(ApiConfig.friendById(friendshipId)),
          headers: headers,
          body: jsonEncode({'action': action}),
        ),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw _handleResponseError(response, 'Failed to respond to request');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to respond to request. Please check your internet connection.');
    }
  }

  Future<void> removeFriend(String friendshipId) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => _client.delete(
          Uri.parse(ApiConfig.friendById(friendshipId)),
          headers: headers,
        ),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        throw _handleResponseError(response, 'Failed to remove friend');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to remove friend. Please check your internet connection.');
    }
  }

  Future<String> requestPasswordReset(String email) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      );
      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        return data['message'] ?? 'Reset instructions sent to your email.';
      } else {
        throw _handleResponseError(response, 'Failed to request password reset');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to request password reset. Please check your internet connection.');
    }
  }

  Future<String> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'otp': otp.trim(),
          'newPassword': newPassword,
        }),
      );
      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        return data['message'] ?? 'Password reset successful.';
      } else {
        throw _handleResponseError(response, 'Failed to reset password');
      }
    } catch (e) {
      throw _handleNetworkError(e, 'Unable to reset password. Please check your internet connection.');
    }
  }

  Future<List<CategoryItem>> fetchCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_categories_json');
      List<CategoryItem> categories = [];
      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List) {
            categories = decoded
                .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }

      final response = await _authenticatedRequest(
        (headers) => _client.get(Uri.parse(ApiConfig.categories), headers: headers),
      );
      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        final list = (data['categories'] as List? ?? []);
        final fetched = list
            .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
        await prefs.setString(
          'cached_categories_json',
          jsonEncode(fetched.map((c) => c.toJson()).toList()),
        );
        return fetched;
      }
      return categories;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_categories_json');
      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List) {
            return decoded
                .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }
      return [];
    }
  }

  Future<CategoryItem> createCategory({
    required String name,
    List<String>? sharedWith,
  }) async {
    try {
      final response = await _authenticatedRequest(
        (headers) => _client.post(
          Uri.parse(ApiConfig.categories),
          headers: headers,
          body: jsonEncode({
            'name': name.trim(),
            'sharedWith': sharedWith ?? [],
          }),
        ),
      );
      final data = _parseJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && data != null) {
        final cat = CategoryItem.fromJson(data['category'] ?? {});
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getString('cached_categories_json');
        List<Map<String, dynamic>> list = [];
        if (cachedJson != null) {
          try {
            final decoded = jsonDecode(cachedJson);
            if (decoded is List) list = List<Map<String, dynamic>>.from(decoded);
          } catch (_) {}
        }
        list.removeWhere((item) => (item['name'] as String?)?.toLowerCase() == cat.name.toLowerCase());
        list.add(cat.toJson());
        await prefs.setString('cached_categories_json', jsonEncode(list));
        return cat;
      } else {
        throw _handleResponseError(response, 'Failed to create category');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      final localCat = CategoryItem(
        id: 'local-cat-${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        sharedWith: const [],
      );
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_categories_json');
      List<Map<String, dynamic>> list = [];
      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson);
          if (decoded is List) list = List<Map<String, dynamic>>.from(decoded);
        } catch (_) {}
      }
      list.add(localCat.toJson());
      await prefs.setString('cached_categories_json', jsonEncode(list));
      return localCat;
    }
  }
}

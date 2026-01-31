import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

/// API Service for HTTP requests to FastAPI backend
class ApiService {
  final http.Client _client;
  String? _authToken;
  
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  
  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }
  
  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }
  
  /// Get headers with optional auth
  Map<String, String> get _headers {
    if (_authToken != null) {
      return ApiConfig.authHeaders(_authToken!);
    }
    return ApiConfig.defaultHeaders;
  }
  
  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiUrl}$endpoint')
          .replace(queryParameters: queryParams);
      
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(ApiConfig.connectionTimeout);
      
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiUrl}$endpoint');
      
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectionTimeout);
      
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// POST request with form-urlencoded body (for OAuth2 login)
  Future<ApiResponse<Map<String, dynamic>>> postForm(
    String endpoint, {
    required Map<String, String> body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiUrl}$endpoint');
      
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(ApiConfig.connectionTimeout);
      
      return _handleResponse(response, (data) => data as Map<String, dynamic>);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiUrl}$endpoint');
      
      final response = await _client
          .put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectionTimeout);
      
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiUrl}$endpoint');
      
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(ApiConfig.connectionTimeout);
      
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  /// Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return ApiResponse.success(null);
      }
      
      final data = jsonDecode(response.body);
      
      if (fromJson != null) {
        return ApiResponse.success(fromJson(data));
      }
      
      return ApiResponse.success(data as T?);
    } else if (statusCode == 401) {
      clearAuthToken();
      return ApiResponse.error('Unauthorized', statusCode: statusCode);
    } else if (statusCode == 404) {
      return ApiResponse.error('Not found', statusCode: statusCode);
    } else {
      String message = 'Request failed';
      try {
        final data = jsonDecode(response.body);
        message = data['detail'] ?? data['message'] ?? message;
      } catch (_) {}
      return ApiResponse.error(message, statusCode: statusCode);
    }
  }
  
  /// Dispose client
  void dispose() {
    _client.close();
  }
}

/// API Response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;
  
  const ApiResponse._({
    this.data,
    this.error,
    this.statusCode,
    required this.isSuccess,
  });
  
  factory ApiResponse.success(T? data) {
    return ApiResponse._(data: data, isSuccess: true);
  }
  
  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse._(
      error: message,
      statusCode: statusCode,
      isSuccess: false,
    );
  }
}

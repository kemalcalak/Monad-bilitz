/// API Configuration for the Signature application
class ApiConfig {
  ApiConfig._();

  /// Base URL for the FastAPI backend
  static const String baseUrl = 'http://localhost:8000';
  
  /// WebSocket URL for real-time updates
  static const String wsUrl = 'ws://localhost:8000/ws';
  
  /// API version prefix
  static const String apiVersion = '/api/v1';
  
  /// Full API URL
  static String get apiUrl => '$baseUrl$apiVersion';
  
  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String contractsEndpoint = '/contracts';
  static const String hierarchyEndpoint = '/hierarchy';
  static const String signaturesEndpoint = '/signatures';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}

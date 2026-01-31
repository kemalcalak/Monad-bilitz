import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../../core/config/api_config.dart';
import '../../domain/entities/user.dart';

/// Repository for authentication operations
class AuthRepository {
  final ApiService _apiService;

  AuthRepository({required ApiService apiService, required LocalStorageService localStorageService})
    : _apiService = apiService;

  /// Login with wallet address
  Future<User?> loginWithWallet(String address, String signature) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${ApiConfig.authEndpoint}/register',
      body: {
        'username': username,
        'email': email,
        'password': password,
        if (walletAddress != null) 'wallet_address': walletAddress,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return UserModel.fromJson(response.data!).toEntity();
    }

    return null;
  }

  /// Login with username and password (OAuth2 form format)
  Future<User?> login({required String username, required String password}) async {
    // Backend uses OAuth2 form format, so we need form-urlencoded
    final response = await _apiService.postForm(
      '${ApiConfig.authEndpoint}/login',
      body: {'username': username, 'password': password},
    );

    if (response.isSuccess && response.data != null) {
      final token = response.data!['access_token'] as String?;
      if (token != null) {
        await _saveToken(token);
        _apiService.setAuthToken(token);

        // Fetch user info after login
        return await getCurrentUser();
      }
    }

    return null;
  }

  /// Login with wallet address (MetaMask)
  Future<User?> loginWithWallet(String address, String signature) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${ApiConfig.authEndpoint}/wallet-connect',
      body: {
        'wallet_address': address,
        'signature': signature,
        'message': 'Sign this message to authenticate with Signature Move Authority',
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final token = response.data!['access_token'] as String?;
      if (token != null) {
        await _saveToken(token);
        _apiService.setAuthToken(token);

        // Fetch user info after login
        return await getCurrentUser();
      }
    }

    return null;
  }

  /// Get current user profile
  Future<User?> getCurrentUser() async {
    // Try to get from local storage first
    final currentUserId = await _localStorageService.getCurrentUserId();
    if (currentUserId != null) {
      final userData = await _localStorageService.findUserById(currentUserId);
      if (userData != null) {
        return User(
          id: userData['id'] as String,
          address: userData['wallet_address'] as String? ?? '',
          name: userData['name'] as String,
          level: userData['level'] as int? ?? 0,
          role: userData['role'] as String? ?? 'Employee',
          supervisorId: userData['parent_id'] as String?,
          isActive: userData['is_active'] as bool? ?? true,
          createdAt: DateTime.now(),
        );
      }
    }

    // Fallback to API
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConfig.authEndpoint}/me',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final user = UserModel.fromJson(response.data!).toEntity();
      await _saveUser(user);
      return user;
    }

    return null;
  }

  /// Logout
  Future<void> logout() async {
    await _apiService.post('${ApiConfig.authEndpoint}/logout');
    _apiService.clearAuthToken();
    await _clearStoredAuth();
  }

  /// Get stored JWT token (for WebSocket auth)
  Future<String?> getStoredToken() async {
    return _getStoredToken();
  }

  /// Check if user is logged in and restore session
  Future<User?> restoreSession() async {
    final token = await _getStoredToken();
    if (token != null) {
      _apiService.setAuthToken(token);

      // Try to get current user with stored token
      final user = await getCurrentUser();
      if (user != null) {
        return user;
      }

      // Token is invalid, clear it
      await _clearStoredAuth();
    }

    return null;
  }

  /// Save JWT token to local storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get stored JWT token
  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Save user to local storage
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _userKey,
      jsonEncode({'id': user.id, 'name': user.name, 'address': user.address, 'role': user.role, 'level': user.level}),
    );
  }

  /// Clear stored auth data
  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}

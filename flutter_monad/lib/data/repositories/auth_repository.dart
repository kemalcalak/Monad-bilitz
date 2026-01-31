import 'dart:math';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../../core/config/api_config.dart';
import '../../domain/entities/user.dart';

/// Repository for authentication operations
class AuthRepository {
  final ApiService _apiService;
  final LocalStorageService _localStorageService;
  
  AuthRepository({
    required ApiService apiService,
    LocalStorageService? localStorageService,
  }) : _apiService = apiService,
       _localStorageService = localStorageService ?? LocalStorageService();
  
  /// Login with user ID and password
  Future<User?> loginWithId(String id, String password) async {
    // Verify credentials
    final isValid = await _localStorageService.verifyCredentials(id, password);
    if (!isValid) return null;
    
    // Get user data
    final userData = await _localStorageService.findUserById(id);
    if (userData == null) return null;
    
    // Save session
    await _localStorageService.saveCurrentUser(id);
    
    // Convert to User entity
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
  
  /// Register new user
  Future<User?> register({
    required String name,
    required String role,
    required String password,
  }) async {
    final random = Random();
    
    // Generate unique ID
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    // Get random parent
    final parent = await _localStorageService.getRandomParent();
    
    // Generate random values
    final level = random.nextInt(3) + 1; // 1-3
    final childrenCount = random.nextInt(3) + 1; // 1-3
    final walletAddress = _localStorageService.generateWalletAddress();
    final isActive = random.nextBool();
    
    // Create new user data
    final newUser = {
      'id': id,
      'name': name,
      'parent_id': parent?['id'],
      'parent_name': parent?['name'],
      'wallet_address': walletAddress,
      'level': level,
      'role': role,
      'is_active': isActive,
      'children_count': childrenCount,
    };
    
    // Save to hierarchy
    await _localStorageService.addUser(newUser);
    
    // Save credentials
    await _localStorageService.saveUserCredentials(id, password);
    
    // Auto-login after registration
    await _localStorageService.saveCurrentUser(id);
    
    return User(
      id: id,
      address: walletAddress,
      name: name,
      level: level,
      role: role,
      supervisorId: parent?['id'] as String?,
      isActive: isActive,
      createdAt: DateTime.now(),
    );
  }
  
  /// Login with wallet address (original method - kept for compatibility)
  Future<User?> loginWithWallet(String address, String signature) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${ApiConfig.authEndpoint}/login',
      body: {
        'address': address,
        'signature': signature,
      },
    );
    
    if (response.isSuccess && response.data != null) {
      final token = response.data!['token'] as String?;
      if (token != null) {
        _apiService.setAuthToken(token);
      }
      
      final userData = response.data!['user'] as Map<String, dynamic>?;
      if (userData != null) {
        return UserModel.fromJson(userData).toEntity();
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
      return UserModel.fromJson(response.data!).toEntity();
    }
    
    return null;
  }
  
  /// Logout
  Future<void> logout() async {
    await _localStorageService.clearCurrentUser();
    await _apiService.post('${ApiConfig.authEndpoint}/logout');
    _apiService.clearAuthToken();
  }
  
  /// Verify signature
  Future<bool> verifySignature(String message, String signature, String address) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${ApiConfig.authEndpoint}/verify',
      body: {
        'message': message,
        'signature': signature,
        'address': address,
      },
    );
    
    if (response.isSuccess && response.data != null) {
      return response.data!['valid'] as bool? ?? false;
    }
    
    return false;
  }
  
  /// Generate nonce for wallet signing
  Future<String?> generateNonce(String address) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${ApiConfig.authEndpoint}/nonce',
      body: {'address': address},
    );
    
    if (response.isSuccess && response.data != null) {
      return response.data!['nonce'] as String?;
    }
    
    return null;
  }
}

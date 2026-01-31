import '../models/user_model.dart';
import '../services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../domain/entities/user.dart';

/// Repository for authentication operations
class AuthRepository {
  final ApiService _apiService;
  
  AuthRepository({required ApiService apiService}) : _apiService = apiService;
  
  /// Login with wallet address
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

import '../models/hierarchy_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../domain/entities/user.dart';

/// Repository for hierarchy operations
class HierarchyRepository {
  final ApiService _apiService;
  
  // Flag to use mock data when API is unavailable
  static const bool _useMockData = true;
  
  HierarchyRepository({required ApiService apiService}) : _apiService = apiService;
  
  /// Get full hierarchy tree
  Future<HierarchyNodeModel?> getHierarchyTree() async {
    if (_useMockData) {
      return _getMockHierarchyTree();
    }
    
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConfig.hierarchyEndpoint}/tree',
      fromJson: (data) => data as Map<String, dynamic>,
    );
    
    if (response.isSuccess && response.data != null) {
      return HierarchyNodeModel.fromJson(response.data!);
    }
    
    // Fall back to mock data if API fails
    return _getMockHierarchyTree();
  }
  
  /// Get hierarchy statistics
  Future<HierarchyStatsModel?> getHierarchyStats() async {
    if (_useMockData) {
      return _getMockHierarchyStats();
    }
    
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConfig.hierarchyEndpoint}/stats',
      fromJson: (data) => data as Map<String, dynamic>,
    );
    
    if (response.isSuccess && response.data != null) {
      return HierarchyStatsModel.fromJson(response.data!);
    }
    
    return _getMockHierarchyStats();
  }
  
  /// Get all members
  Future<List<User>> getAllMembers() async {
    if (_useMockData) {
      return _getMockMembers();
    }
    
    final response = await _apiService.get<List<dynamic>>(
      '${ApiConfig.hierarchyEndpoint}/members',
      fromJson: (data) => data as List<dynamic>,
    );
    
    if (response.isSuccess && response.data != null) {
      return response.data!
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
    }
    
    return _getMockMembers();
  }
  
  /// Get member by ID
  Future<User?> getMemberById(String id) async {
    if (_useMockData) {
      final members = _getMockMembers();
      return members.where((m) => m.id == id).firstOrNull;
    }
    
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConfig.hierarchyEndpoint}/members/$id',
      fromJson: (data) => data as Map<String, dynamic>,
    );
    
    if (response.isSuccess && response.data != null) {
      return UserModel.fromJson(response.data!).toEntity();
    }
    
    return null;
  }
  
  /// Add new member to hierarchy
  Future<User?> addMember({
    required String address,
    required String name,
    required int level,
    required String supervisorId,
  }) async {
    if (_useMockData) {
      // Return a mock added member
      return User(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        address: address,
        name: name,
        level: level,
        role: _getRoleForLevel(level),
        supervisorId: supervisorId,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }
    
    final response = await _apiService.post<Map<String, dynamic>>(
      '${ApiConfig.hierarchyEndpoint}/members',
      body: {
        'address': address,
        'name': name,
        'level': level,
        'supervisor_id': supervisorId,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    
    if (response.isSuccess && response.data != null) {
      return UserModel.fromJson(response.data!).toEntity();
    }
    
    return null;
  }
  
  /// Get subordinates of a member
  Future<List<User>> getSubordinates(String memberId) async {
    if (_useMockData) {
      final members = _getMockMembers();
      return members.where((m) => m.supervisorId == memberId).toList();
    }
    
    final response = await _apiService.get<List<dynamic>>(
      '${ApiConfig.hierarchyEndpoint}/members/$memberId/subordinates',
      fromJson: (data) => data as List<dynamic>,
    );
    
    if (response.isSuccess && response.data != null) {
      return response.data!
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
    }
    
    return [];
  }
  
  /// Get supervisors chain for a member
  Future<List<User>> getSupervisorsChain(String memberId) async {
    if (_useMockData) {
      return []; // Simplified for mock
    }
    
    final response = await _apiService.get<List<dynamic>>(
      '${ApiConfig.hierarchyEndpoint}/members/$memberId/supervisors',
      fromJson: (data) => data as List<dynamic>,
    );
    
    if (response.isSuccess && response.data != null) {
      return response.data!
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
    }
    
    return [];
  }
  
  /// Deactivate a member
  Future<bool> deactivateMember(String memberId) async {
    if (_useMockData) {
      return true;
    }
    
    final response = await _apiService.delete(
      '${ApiConfig.hierarchyEndpoint}/members/$memberId',
    );
    
    return response.isSuccess;
  }
  
  // ==================== MOCK DATA ====================
  
  String _getRoleForLevel(int level) {
    switch (level) {
      case 0: return 'CEO';
      case 1: return 'Director';
      case 2: return 'Manager';
      case 3: return 'Team Lead';
      default: return 'Employee';
    }
  }
  
  HierarchyNodeModel _getMockHierarchyTree() {
    return const HierarchyNodeModel(
      id: 'ceo_001',
      address: '0x1234567890abcdef1234567890abcdef12345678',
      name: 'Alice Johnson',
      level: 0,
      role: 'CEO',
      isActive: true,
      children: [
        HierarchyNodeModel(
          id: 'dir_001',
          address: '0x2345678901abcdef2345678901abcdef23456789',
          name: 'Bob Smith',
          level: 1,
          role: 'Tech Director',
          supervisorId: 'ceo_001',
          isActive: true,
          children: [
            HierarchyNodeModel(
              id: 'mgr_001',
              address: '0x3456789012abcdef3456789012abcdef34567890',
              name: 'Charlie Brown',
              level: 2,
              role: 'Engineering Manager',
              supervisorId: 'dir_001',
              isActive: true,
              children: [
                HierarchyNodeModel(
                  id: 'emp_001',
                  address: '0x4567890123abcdef4567890123abcdef45678901',
                  name: 'Diana Lee',
                  level: 4,
                  role: 'Senior Developer',
                  supervisorId: 'mgr_001',
                  isActive: true,
                ),
                HierarchyNodeModel(
                  id: 'emp_002',
                  address: '0x5678901234abcdef5678901234abcdef56789012',
                  name: 'Edward Kim',
                  level: 4,
                  role: 'Developer',
                  supervisorId: 'mgr_001',
                  isActive: true,
                ),
              ],
            ),
            HierarchyNodeModel(
              id: 'mgr_002',
              address: '0x6789012345abcdef6789012345abcdef67890123',
              name: 'Fiona Garcia',
              level: 2,
              role: 'Product Manager',
              supervisorId: 'dir_001',
              isActive: true,
              children: [
                HierarchyNodeModel(
                  id: 'emp_003',
                  address: '0x7890123456abcdef7890123456abcdef78901234',
                  name: 'George Wilson',
                  level: 4,
                  role: 'UI Designer',
                  supervisorId: 'mgr_002',
                  isActive: true,
                ),
              ],
            ),
          ],
        ),
        HierarchyNodeModel(
          id: 'dir_002',
          address: '0x8901234567abcdef8901234567abcdef89012345',
          name: 'Helen Martinez',
          level: 1,
          role: 'Finance Director',
          supervisorId: 'ceo_001',
          isActive: true,
          children: [
            HierarchyNodeModel(
              id: 'mgr_003',
              address: '0x9012345678abcdef9012345678abcdef90123456',
              name: 'Ivan Chen',
              level: 2,
              role: 'Finance Manager',
              supervisorId: 'dir_002',
              isActive: true,
              children: [
                HierarchyNodeModel(
                  id: 'emp_004',
                  address: '0xa123456789abcdefa123456789abcdefa1234567',
                  name: 'Julia Roberts',
                  level: 4,
                  role: 'Accountant',
                  supervisorId: 'mgr_003',
                  isActive: true,
                ),
              ],
            ),
          ],
        ),
        HierarchyNodeModel(
          id: 'dir_003',
          address: '0xb234567890abcdefb234567890abcdefb2345678',
          name: 'Kevin Park',
          level: 1,
          role: 'Operations Director',
          supervisorId: 'ceo_001',
          isActive: false, // Inactive example
        ),
      ],
    );
  }
  
  HierarchyStatsModel _getMockHierarchyStats() {
    return const HierarchyStatsModel(
      totalMembers: 11,
      activeMembers: 10,
      pendingContracts: 5,
      pendingSignatures: 3,
      levelDistribution: {
        '0': 1,  // CEO
        '1': 3,  // Directors
        '2': 3,  // Managers
        '4': 4,  // Employees
      },
    );
  }
  
  List<User> _getMockMembers() {
    final now = DateTime.now();
    return [
      User(id: 'ceo_001', address: '0x1234...5678', name: 'Alice Johnson', level: 0, role: 'CEO', isActive: true, createdAt: now),
      User(id: 'dir_001', address: '0x2345...6789', name: 'Bob Smith', level: 1, role: 'Tech Director', supervisorId: 'ceo_001', isActive: true, createdAt: now),
      User(id: 'dir_002', address: '0x8901...2345', name: 'Helen Martinez', level: 1, role: 'Finance Director', supervisorId: 'ceo_001', isActive: true, createdAt: now),
      User(id: 'dir_003', address: '0xb234...5678', name: 'Kevin Park', level: 1, role: 'Operations Director', supervisorId: 'ceo_001', isActive: false, createdAt: now),
      User(id: 'mgr_001', address: '0x3456...7890', name: 'Charlie Brown', level: 2, role: 'Engineering Manager', supervisorId: 'dir_001', isActive: true, createdAt: now),
      User(id: 'mgr_002', address: '0x6789...0123', name: 'Fiona Garcia', level: 2, role: 'Product Manager', supervisorId: 'dir_001', isActive: true, createdAt: now),
      User(id: 'mgr_003', address: '0x9012...3456', name: 'Ivan Chen', level: 2, role: 'Finance Manager', supervisorId: 'dir_002', isActive: true, createdAt: now),
      User(id: 'emp_001', address: '0x4567...8901', name: 'Diana Lee', level: 4, role: 'Senior Developer', supervisorId: 'mgr_001', isActive: true, createdAt: now),
      User(id: 'emp_002', address: '0x5678...9012', name: 'Edward Kim', level: 4, role: 'Developer', supervisorId: 'mgr_001', isActive: true, createdAt: now),
      User(id: 'emp_003', address: '0x7890...1234', name: 'George Wilson', level: 4, role: 'UI Designer', supervisorId: 'mgr_002', isActive: true, createdAt: now),
      User(id: 'emp_004', address: '0xa123...4567', name: 'Julia Roberts', level: 4, role: 'Accountant', supervisorId: 'mgr_003', isActive: true, createdAt: now),
    ];
  }
}

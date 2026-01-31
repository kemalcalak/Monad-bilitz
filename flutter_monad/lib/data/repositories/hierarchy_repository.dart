import '../models/hierarchy_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../domain/entities/user.dart';

/// Repository for hierarchy operations
class HierarchyRepository {
  final ApiService _apiService;

  // Flag to use mock data when API is unavailable
  static const bool _useMockData = false;

  HierarchyRepository({required ApiService apiService}) : _apiService = apiService;

  /// Get full hierarchy tree (from backend graph endpoint)
  Future<HierarchyNodeModel?> getHierarchyTree() async {
    if (_useMockData) {
      return _getMockHierarchyTree();
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConfig.hierarchyEndpoint}/graph',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return _convertGraphToTree(response.data!);
    }

    return _getMockHierarchyTree();
  }

  /// Convert backend graph format to tree structure
  HierarchyNodeModel? _convertGraphToTree(Map<String, dynamic> graphData) {
    final nodes = graphData['nodes'] as List<dynamic>? ?? [];
    final edges = graphData['edges'] as List<dynamic>? ?? [];

    if (nodes.isEmpty) return null;

    // Build node map
    final nodeMap = <String, Map<String, dynamic>>{};
    for (final node in nodes) {
      final nodeData = node as Map<String, dynamic>;
      nodeMap[nodeData['id'] as String] = nodeData;
    }

    // Build children map from edges
    final childrenMap = <String, List<String>>{};
    for (final edge in edges) {
      final edgeData = edge as Map<String, dynamic>;
      final source = edgeData['source'] as String? ?? edgeData['from'] as String?;
      final target = edgeData['target'] as String? ?? edgeData['to'] as String?;
      if (source != null && target != null) {
        childrenMap.putIfAbsent(source, () => []).add(target);
      }
    }

    // Find root node (node with no parent or level 0)
    String? rootId;
    for (final node in nodes) {
      final nodeData = node as Map<String, dynamic>;
      if (nodeData['level'] == 0 || nodeData['level'] == '0') {
        rootId = nodeData['id'] as String;
        break;
      }
    }

    if (rootId == null && nodes.isNotEmpty) {
      rootId = (nodes.first as Map<String, dynamic>)['id'] as String;
    }

    if (rootId == null) return null;

    return _buildNodeFromGraph(rootId, nodeMap, childrenMap);
  }

  HierarchyNodeModel _buildNodeFromGraph(
    String nodeId,
    Map<String, Map<String, dynamic>> nodeMap,
    Map<String, List<String>> childrenMap,
  ) {
    final data = nodeMap[nodeId]!;
    final childIds = childrenMap[nodeId] ?? [];

    return HierarchyNodeModel(
      id: nodeId,
      name: data['group_name'] as String? ?? data['display_name'] as String? ?? 'Unknown',
      address: data['wallet_address'] as String? ?? '',
      level: (data['level'] as num?)?.toInt() ?? 0,
      role: data['display_name'] as String? ?? data['group_name'] as String? ?? '',
      supervisorId: null,
      isActive: true,
      children: childIds.map((id) => _buildNodeFromGraph(id, nodeMap, childrenMap)).toList(),
    );
  }

  /// Get hierarchy statistics (from backend groups + contracts endpoints)
  Future<HierarchyStatsModel?> getHierarchyStats() async {
    if (_useMockData) {
      return _getMockHierarchyStats();
    }

    // Get groups to calculate member stats
    final groupsResponse = await _apiService.get<List<dynamic>>(
      '${ApiConfig.hierarchyEndpoint}/groups',
      fromJson: (data) => data as List<dynamic>,
    );

    // Get pending contracts count
    final pendingResponse = await _apiService.get<List<dynamic>>(
      ApiConfig.contractsEndpoint,
      queryParams: {'status_filter': 'pending'},
      fromJson: (data) => data as List<dynamic>,
    );

    int totalMembers = 0;
    final levelDistribution = <String, int>{};

    if (groupsResponse.isSuccess && groupsResponse.data != null) {
      for (final group in groupsResponse.data!) {
        final groupData = group as Map<String, dynamic>;
        final count = (groupData['user_count'] as num?)?.toInt() ?? 0;
        final level = (groupData['level'] as num?)?.toInt() ?? 0;
        totalMembers += count;
        levelDistribution['$level'] = (levelDistribution['$level'] ?? 0) + count;
      }
    }

    int pendingContracts = 0;
    if (pendingResponse.isSuccess && pendingResponse.data != null) {
      pendingContracts = pendingResponse.data!.length;
    }

    if (totalMembers == 0 && !groupsResponse.isSuccess) {
      return _getMockHierarchyStats();
    }

    return HierarchyStatsModel(
      totalMembers: totalMembers,
      activeMembers: totalMembers,
      pendingContracts: pendingContracts,
      pendingSignatures: 0,
      levelDistribution: levelDistribution,
    );
  }

  /// Get all members (from backend /hierarchy/members endpoint)
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

    // Use the members list and filter client-side
    final members = await getAllMembers();
    return members.where((m) => m.id == id).firstOrNull;
  }

  /// Create a new group in hierarchy (matches backend POST /hierarchy/groups)
  Future<Map<String, dynamic>?> createGroup({
    required String groupName,
    required String displayName,
    required int level,
    required int authorityScore,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${ApiConfig.hierarchyEndpoint}/groups',
      body: {
        'group_name': groupName,
        'display_name': displayName,
        'level': level,
        'authority_score': authorityScore,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return response.data;
    }

    return null;
  }

  /// Add new member to hierarchy (creates a group or assigns user)
  Future<User?> addMember({
    required String address,
    required String name,
    required int level,
    required String supervisorId,
  }) async {
    if (_useMockData) {
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

    // Use createGroup as backend organizes by groups
    final result = await createGroup(
      groupName: name.toLowerCase().replaceAll(' ', '_'),
      displayName: name,
      level: level,
      authorityScore: _getScoreForLevel(level),
    );

    if (result != null) {
      return User(
        id: result['id'] as String? ?? '',
        address: address,
        name: name,
        level: level,
        role: result['display_name'] as String? ?? name,
        supervisorId: supervisorId,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  /// Get subordinates of a member (derived from members list)
  Future<List<User>> getSubordinates(String memberId) async {
    if (_useMockData) {
      final members = _getMockMembers();
      return members.where((m) => m.supervisorId == memberId).toList();
    }

    // Backend does not have a dedicated subordinates endpoint
    // Filter from all members client-side
    final members = await getAllMembers();
    return members.where((m) => m.supervisorId == memberId).toList();
  }

  /// Get supervisors chain for a member
  Future<List<User>> getSupervisorsChain(String memberId) async {
    // Backend does not have a dedicated supervisors endpoint
    return [];
  }

  /// Deactivate a member
  Future<bool> deactivateMember(String memberId) async {
    // Backend does not have a dedicated deactivate endpoint
    return false;
  }

  /// Get current user's authority score
  Future<Map<String, dynamic>?> getMyAuthorityScore() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConfig.hierarchyEndpoint}/my-authority-score',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return response.data;
    }

    return null;
  }

  // ==================== HELPERS ====================

  String _getRoleForLevel(int level) {
    switch (level) {
      case 0: return 'CEO';
      case 1: return 'Director';
      case 2: return 'Manager';
      case 3: return 'Team Lead';
      default: return 'Employee';
    }
  }

  int _getScoreForLevel(int level) {
    switch (level) {
      case 0: return 100;
      case 1: return 80;
      case 2: return 50;
      case 3: return 30;
      default: return 10;
    }
  }

  // ==================== MOCK DATA ====================

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
          isActive: false,
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
        '0': 1,
        '1': 3,
        '2': 3,
        '4': 4,
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

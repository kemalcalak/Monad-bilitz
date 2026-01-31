import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'hierarchy_model.g.dart';

/// Hierarchy tree node model
@JsonSerializable()
class HierarchyNodeModel {
  final String id;
  final String address;
  final String name;
  final int level;
  final String role;
  @JsonKey(name: 'supervisor_id')
  final String? supervisorId;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final List<HierarchyNodeModel> children;
  
  const HierarchyNodeModel({
    required this.id,
    required this.address,
    required this.name,
    required this.level,
    required this.role,
    this.supervisorId,
    this.isActive = true,
    this.children = const [],
  });
  
  factory HierarchyNodeModel.fromJson(Map<String, dynamic> json) => 
      _$HierarchyNodeModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$HierarchyNodeModelToJson(this);
  
  /// Get all descendants count
  int get descendantsCount {
    int count = children.length;
    for (final child in children) {
      count += child.descendantsCount;
    }
    return count;
  }
  
  /// Find a node by ID
  HierarchyNodeModel? findById(String nodeId) {
    if (id == nodeId) return this;
    for (final child in children) {
      final found = child.findById(nodeId);
      if (found != null) return found;
    }
    return null;
  }
  
  /// Convert to User entity (without children)
  User toUserEntity() {
    return User(
      id: id,
      address: address,
      name: name,
      level: level,
      role: role,
      supervisorId: supervisorId,
      isActive: isActive,
      createdAt: DateTime.now(),
    );
  }
}

/// Hierarchy statistics model
@JsonSerializable()
class HierarchyStatsModel {
  @JsonKey(name: 'total_members')
  final int totalMembers;
  @JsonKey(name: 'active_members')
  final int activeMembers;
  @JsonKey(name: 'pending_contracts')
  final int pendingContracts;
  @JsonKey(name: 'pending_signatures')
  final int pendingSignatures;
  @JsonKey(name: 'level_distribution')
  final Map<String, int> levelDistribution;
  
  const HierarchyStatsModel({
    required this.totalMembers,
    required this.activeMembers,
    required this.pendingContracts,
    required this.pendingSignatures,
    required this.levelDistribution,
  });
  
  factory HierarchyStatsModel.fromJson(Map<String, dynamic> json) => 
      _$HierarchyStatsModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$HierarchyStatsModelToJson(this);
}

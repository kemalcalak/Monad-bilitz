import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// User model that matches backend UserResponse
@JsonSerializable()
class UserModel {
  final String id;
  final String username;
  final String? email;
  @JsonKey(name: 'wallet_address')
  final String? walletAddress;
  @JsonKey(name: 'group_name')
  final String? groupName;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  // Legacy fields for backward compatibility
  final String? address;
  final String? name;
  final int? level;
  final String? role;
  @JsonKey(name: 'supervisor_id')
  final String? supervisorId;
  @JsonKey(name: 'hkas_key_hash')
  final String? hkasKeyHash;
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  const UserModel({
    required this.id,
    required this.username,
    this.email,
    this.walletAddress,
    this.groupName,
    this.createdAt,
    this.address,
    this.name,
    this.level,
    this.role,
    this.supervisorId,
    this.hkasKeyHash,
    this.isActive = true,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
  
  /// Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      address: walletAddress ?? address ?? '',
      name: name ?? username,
      level: level ?? _levelFromGroupName(groupName),
      role: role ?? groupName ?? 'User',
      supervisorId: supervisorId,
      hkasKeyHash: hkasKeyHash,
      isActive: isActive,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
  
  /// Infer level from group name if not provided
  int _levelFromGroupName(String? groupName) {
    if (groupName == null) return 4;
    switch (groupName.toLowerCase()) {
      case 'ceo':
      case 'executive':
        return 0;
      case 'director':
        return 1;
      case 'manager':
        return 2;
      case 'team_lead':
        return 3;
      default:
        return 4;
    }
  }
  
  /// Create from domain entity
  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      username: entity.name,
      address: entity.address,
      name: entity.name,
      level: entity.level,
      role: entity.role,
      supervisorId: entity.supervisorId,
      hkasKeyHash: entity.hkasKeyHash,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}

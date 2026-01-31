import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String address;
  final String name;
  final int level;
  final String role;
  @JsonKey(name: 'supervisor_id')
  final String? supervisorId;
  @JsonKey(name: 'hkas_key_hash')
  final String? hkasKeyHash;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  const UserModel({
    required this.id,
    required this.address,
    required this.name,
    required this.level,
    required this.role,
    this.supervisorId,
    this.hkasKeyHash,
    this.isActive = true,
    required this.createdAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
  
  /// Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      address: address,
      name: name,
      level: level,
      role: role,
      supervisorId: supervisorId,
      hkasKeyHash: hkasKeyHash,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
  
  /// Create from domain entity
  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
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

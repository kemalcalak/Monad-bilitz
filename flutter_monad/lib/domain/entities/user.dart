import 'package:equatable/equatable.dart';

/// User entity representing a hierarchy member
class User extends Equatable {
  final String id;
  final String address; // Blockchain address
  final String name;
  final int level;
  final String role;
  final String? supervisorId;
  final String? hkasKeyHash;
  final bool isActive;
  final DateTime createdAt;
  
  const User({
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
  
  /// Check if this user can approve for target user
  bool canApproveFor(User target) {
    return level < target.level;
  }
  
  /// Check if this user has higher authority
  bool hasHigherAuthorityThan(User other) {
    return level < other.level;
  }
  
  User copyWith({
    String? id,
    String? address,
    String? name,
    int? level,
    String? role,
    String? supervisorId,
    String? hkasKeyHash,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      address: address ?? this.address,
      name: name ?? this.name,
      level: level ?? this.level,
      role: role ?? this.role,
      supervisorId: supervisorId ?? this.supervisorId,
      hkasKeyHash: hkasKeyHash ?? this.hkasKeyHash,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    address,
    name,
    level,
    role,
    supervisorId,
    hkasKeyHash,
    isActive,
    createdAt,
  ];
}

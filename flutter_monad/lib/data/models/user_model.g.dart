// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  username: json['username'] as String,
  email: json['email'] as String?,
  walletAddress: json['wallet_address'] as String?,
  groupName: json['group_name'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  address: json['address'] as String?,
  name: json['name'] as String?,
  level: (json['level'] as num?)?.toInt(),
  role: json['role'] as String?,
  supervisorId: json['supervisor_id'] as String?,
  hkasKeyHash: json['hkas_key_hash'] as String?,
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'wallet_address': instance.walletAddress,
  'group_name': instance.groupName,
  'created_at': instance.createdAt?.toIso8601String(),
  'address': instance.address,
  'name': instance.name,
  'level': instance.level,
  'role': instance.role,
  'supervisor_id': instance.supervisorId,
  'hkas_key_hash': instance.hkasKeyHash,
  'is_active': instance.isActive,
};

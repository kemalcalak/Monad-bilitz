// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hierarchy_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HierarchyNodeModel _$HierarchyNodeModelFromJson(Map<String, dynamic> json) =>
    HierarchyNodeModel(
      id: json['id'] as String,
      address: json['address'] as String,
      name: json['name'] as String,
      level: (json['level'] as num).toInt(),
      role: json['role'] as String,
      supervisorId: json['supervisor_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      children:
          (json['children'] as List<dynamic>?)
              ?.map(
                (e) => HierarchyNodeModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$HierarchyNodeModelToJson(HierarchyNodeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'name': instance.name,
      'level': instance.level,
      'role': instance.role,
      'supervisor_id': instance.supervisorId,
      'is_active': instance.isActive,
      'children': instance.children,
    };

HierarchyStatsModel _$HierarchyStatsModelFromJson(Map<String, dynamic> json) =>
    HierarchyStatsModel(
      totalMembers: (json['total_members'] as num).toInt(),
      activeMembers: (json['active_members'] as num).toInt(),
      pendingContracts: (json['pending_contracts'] as num).toInt(),
      pendingSignatures: (json['pending_signatures'] as num).toInt(),
      levelDistribution: Map<String, int>.from(
        json['level_distribution'] as Map,
      ),
    );

Map<String, dynamic> _$HierarchyStatsModelToJson(
  HierarchyStatsModel instance,
) => <String, dynamic>{
  'total_members': instance.totalMembers,
  'active_members': instance.activeMembers,
  'pending_contracts': instance.pendingContracts,
  'pending_signatures': instance.pendingSignatures,
  'level_distribution': instance.levelDistribution,
};

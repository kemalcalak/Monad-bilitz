// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContractModel _$ContractModelFromJson(Map<String, dynamic> json) =>
    ContractModel(
      id: json['id'] as String,
      title: json['title'] as String,
      contentHash: json['content_hash'] as String,
      creatorId: json['creator_id'] as String,
      requiredApproverIds: (json['required_approver_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      approvedByIds: (json['approved_by_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      status: json['status'] as String,
      minApprovalLevel: (json['min_approval_level'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ContractModelToJson(ContractModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content_hash': instance.contentHash,
      'creator_id': instance.creatorId,
      'required_approver_ids': instance.requiredApproverIds,
      'approved_by_ids': instance.approvedByIds,
      'status': instance.status,
      'min_approval_level': instance.minApprovalLevel,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'description': instance.description,
    };

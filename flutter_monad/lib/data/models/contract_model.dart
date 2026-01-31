import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/contract.dart';

part 'contract_model.g.dart';

@JsonSerializable()
class ContractModel {
  final String id;
  final String title;
  @JsonKey(name: 'content_hash')
  final String contentHash;
  @JsonKey(name: 'creator_id')
  final String creatorId;
  @JsonKey(name: 'required_approver_ids')
  final List<String> requiredApproverIds;
  @JsonKey(name: 'approved_by_ids')
  final List<String> approvedByIds;
  final String status;
  @JsonKey(name: 'min_approval_level')
  final int minApprovalLevel;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  final String? description;
  
  const ContractModel({
    required this.id,
    required this.title,
    required this.contentHash,
    required this.creatorId,
    required this.requiredApproverIds,
    required this.approvedByIds,
    required this.status,
    required this.minApprovalLevel,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.description,
  });
  
  factory ContractModel.fromJson(Map<String, dynamic> json) => 
      _$ContractModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ContractModelToJson(this);
  
  /// Convert to domain entity
  Contract toEntity() {
    return Contract(
      id: id,
      title: title,
      contentHash: contentHash,
      creatorId: creatorId,
      requiredApproverIds: requiredApproverIds,
      approvedByIds: approvedByIds,
      status: _parseStatus(status),
      minApprovalLevel: minApprovalLevel,
      createdAt: createdAt,
      updatedAt: updatedAt,
      expiresAt: expiresAt,
      description: description,
    );
  }
  
  /// Create from domain entity
  factory ContractModel.fromEntity(Contract entity) {
    return ContractModel(
      id: entity.id,
      title: entity.title,
      contentHash: entity.contentHash,
      creatorId: entity.creatorId,
      requiredApproverIds: entity.requiredApproverIds,
      approvedByIds: entity.approvedByIds,
      status: entity.status.name.toUpperCase(),
      minApprovalLevel: entity.minApprovalLevel,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      expiresAt: entity.expiresAt,
      description: entity.description,
    );
  }
  
  ContractStatusEnum _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return ContractStatusEnum.draft;
      case 'PENDING_APPROVAL':
        return ContractStatusEnum.pendingApproval;
      case 'APPROVED':
        return ContractStatusEnum.approved;
      case 'REJECTED':
        return ContractStatusEnum.rejected;
      case 'EXECUTED':
        return ContractStatusEnum.executed;
      case 'CANCELLED':
        return ContractStatusEnum.cancelled;
      default:
        return ContractStatusEnum.draft;
    }
  }
}

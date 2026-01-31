import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/contract.dart';

part 'contract_model.g.dart';

/// Contract model that matches backend ContractResponse
@JsonSerializable()
class ContractModel {
  final String id;
  @JsonKey(name: 'contract_id')
  final String contractId;
  final String title;
  final String content;
  @JsonKey(name: 'contract_type')
  final String contractType;
  final double? amount;
  @JsonKey(name: 'required_score')
  final int requiredScore;
  @JsonKey(name: 'current_score')
  final int currentScore;
  final String status;
  @JsonKey(name: 'creator_id')
  final String creatorId;
  @JsonKey(name: 'creator_username')
  final String? creatorUsername;
  @JsonKey(name: 'blockchain_tx_hash')
  final String? blockchainTxHash;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final List<SignatureModel>? signatures;
  
  const ContractModel({
    required this.id,
    required this.contractId,
    required this.title,
    required this.content,
    required this.contractType,
    this.amount,
    required this.requiredScore,
    required this.currentScore,
    required this.status,
    required this.creatorId,
    this.creatorUsername,
    this.blockchainTxHash,
    required this.createdAt,
    this.signatures,
  });
  
  factory ContractModel.fromJson(Map<String, dynamic> json) => 
      _$ContractModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ContractModelToJson(this);
  
  /// Convert to domain entity
  Contract toEntity() {
    return Contract(
      id: contractId,
      title: title,
      contentHash: content, // Using content as contentHash for now
      creatorId: creatorId,
      requiredApproverIds: [], // Not directly available from backend
      approvedByIds: signatures?.map((s) => s.signerId).toList() ?? [],
      status: _parseStatus(status),
      minApprovalLevel: requiredScore,
      createdAt: createdAt,
      updatedAt: createdAt, // Backend doesn't have updated_at
      description: '$contractType - ${amount != null ? "\$$amount" : "N/A"}',
    );
  }
  
  ContractStatusEnum _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return ContractStatusEnum.draft;
      case 'pending':
      case 'pending_approval':
        return ContractStatusEnum.pendingApproval;
      case 'approved':
      case 'completed':
        return ContractStatusEnum.approved;
      case 'rejected':
        return ContractStatusEnum.rejected;
      case 'executed':
        return ContractStatusEnum.executed;
      case 'cancelled':
        return ContractStatusEnum.cancelled;
      default:
        return ContractStatusEnum.pendingApproval;
    }
  }
}

/// Signature model from backend
@JsonSerializable()
class SignatureModel {
  @JsonKey(name: 'signer_username')
  final String signerUsername;
  @JsonKey(name: 'signer_id')
  final String signerId;
  @JsonKey(name: 'authority_score')
  final int authorityScore;
  @JsonKey(name: 'signed_at')
  final String signedAt;
  
  const SignatureModel({
    required this.signerUsername,
    this.signerId = '',
    required this.authorityScore,
    required this.signedAt,
  });
  
  factory SignatureModel.fromJson(Map<String, dynamic> json) => 
      _$SignatureModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$SignatureModelToJson(this);
}

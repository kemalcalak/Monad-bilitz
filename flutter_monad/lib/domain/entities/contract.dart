import 'package:equatable/equatable.dart';

/// Contract entity representing a document requiring signatures
class Contract extends Equatable {
  final String id;
  final String title;
  final String contentHash;
  final String creatorId;
  final List<String> requiredApproverIds;
  final List<String> approvedByIds;
  final ContractStatusEnum status;
  final int minApprovalLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final String? description;
  
  const Contract({
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
  
  /// Check if contract is pending approval
  bool get isPending => status == ContractStatusEnum.pendingApproval;
  
  /// Check if contract is approved
  bool get isApproved => status == ContractStatusEnum.approved;
  
  /// Check if contract is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  /// Get approval progress percentage
  double get approvalProgress {
    if (requiredApproverIds.isEmpty) return 1.0;
    return approvedByIds.length / requiredApproverIds.length;
  }
  
  /// Check if user has already approved
  bool hasApprovedBy(String userId) {
    return approvedByIds.contains(userId);
  }
  
  Contract copyWith({
    String? id,
    String? title,
    String? contentHash,
    String? creatorId,
    List<String>? requiredApproverIds,
    List<String>? approvedByIds,
    ContractStatusEnum? status,
    int? minApprovalLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    String? description,
  }) {
    return Contract(
      id: id ?? this.id,
      title: title ?? this.title,
      contentHash: contentHash ?? this.contentHash,
      creatorId: creatorId ?? this.creatorId,
      requiredApproverIds: requiredApproverIds ?? this.requiredApproverIds,
      approvedByIds: approvedByIds ?? this.approvedByIds,
      status: status ?? this.status,
      minApprovalLevel: minApprovalLevel ?? this.minApprovalLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      description: description ?? this.description,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    title,
    contentHash,
    creatorId,
    requiredApproverIds,
    approvedByIds,
    status,
    minApprovalLevel,
    createdAt,
    updatedAt,
    expiresAt,
    description,
  ];
}

/// Contract status enum
enum ContractStatusEnum {
  draft,
  pendingApproval,
  approved,
  rejected,
  executed,
  cancelled,
}

extension ContractStatusExtension on ContractStatusEnum {
  String get displayName {
    switch (this) {
      case ContractStatusEnum.draft:
        return 'Draft';
      case ContractStatusEnum.pendingApproval:
        return 'Pending Approval';
      case ContractStatusEnum.approved:
        return 'Approved';
      case ContractStatusEnum.rejected:
        return 'Rejected';
      case ContractStatusEnum.executed:
        return 'Executed';
      case ContractStatusEnum.cancelled:
        return 'Cancelled';
    }
  }
  
  int get colorValue {
    switch (this) {
      case ContractStatusEnum.draft:
        return 0xFF9E9E9E;
      case ContractStatusEnum.pendingApproval:
        return 0xFFFFC107;
      case ContractStatusEnum.approved:
        return 0xFF4CAF50;
      case ContractStatusEnum.rejected:
        return 0xFFF44336;
      case ContractStatusEnum.executed:
        return 0xFF2196F3;
      case ContractStatusEnum.cancelled:
        return 0xFF607D8B;
    }
  }
}

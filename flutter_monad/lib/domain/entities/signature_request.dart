import 'package:equatable/equatable.dart';

/// Signature request entity
class SignatureRequest extends Equatable {
  final String id;
  final String dataHash;
  final String requesterId;
  final String targetSignerId;
  final String? signature;
  final SignatureRequestStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? metadata;
  
  const SignatureRequest({
    required this.id,
    required this.dataHash,
    required this.requesterId,
    required this.targetSignerId,
    this.signature,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.metadata,
  });
  
  /// Check if request is pending
  bool get isPending => status == SignatureRequestStatus.pending;
  
  /// Check if request is signed
  bool get isSigned => status == SignatureRequestStatus.signed;
  
  /// Check if request is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  /// Get remaining time until expiry
  Duration get remainingTime {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }
  
  SignatureRequest copyWith({
    String? id,
    String? dataHash,
    String? requesterId,
    String? targetSignerId,
    String? signature,
    SignatureRequestStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? metadata,
  }) {
    return SignatureRequest(
      id: id ?? this.id,
      dataHash: dataHash ?? this.dataHash,
      requesterId: requesterId ?? this.requesterId,
      targetSignerId: targetSignerId ?? this.targetSignerId,
      signature: signature ?? this.signature,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    dataHash,
    requesterId,
    targetSignerId,
    signature,
    status,
    createdAt,
    expiresAt,
    metadata,
  ];
}

/// Signature request status enum
enum SignatureRequestStatus {
  pending,
  signed,
  rejected,
  expired,
}

extension SignatureRequestStatusExtension on SignatureRequestStatus {
  String get displayName {
    switch (this) {
      case SignatureRequestStatus.pending:
        return 'Pending';
      case SignatureRequestStatus.signed:
        return 'Signed';
      case SignatureRequestStatus.rejected:
        return 'Rejected';
      case SignatureRequestStatus.expired:
        return 'Expired';
    }
  }
  
  int get colorValue {
    switch (this) {
      case SignatureRequestStatus.pending:
        return 0xFFFFC107;
      case SignatureRequestStatus.signed:
        return 0xFF4CAF50;
      case SignatureRequestStatus.rejected:
        return 0xFFF44336;
      case SignatureRequestStatus.expired:
        return 0xFF607D8B;
    }
  }
}

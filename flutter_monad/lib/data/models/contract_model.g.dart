// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContractModel _$ContractModelFromJson(Map<String, dynamic> json) =>
    ContractModel(
      id: json['id'] as String,
      contractId: json['contract_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      contractType: json['contract_type'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      requiredScore: (json['required_score'] as num).toInt(),
      currentScore: (json['current_score'] as num).toInt(),
      status: json['status'] as String,
      creatorId: json['creator_id'] as String,
      creatorUsername: json['creator_username'] as String?,
      blockchainTxHash: json['blockchain_tx_hash'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      signatures: (json['signatures'] as List<dynamic>?)
          ?.map((e) => SignatureModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ContractModelToJson(ContractModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contract_id': instance.contractId,
      'title': instance.title,
      'content': instance.content,
      'contract_type': instance.contractType,
      'amount': instance.amount,
      'required_score': instance.requiredScore,
      'current_score': instance.currentScore,
      'status': instance.status,
      'creator_id': instance.creatorId,
      'creator_username': instance.creatorUsername,
      'blockchain_tx_hash': instance.blockchainTxHash,
      'created_at': instance.createdAt.toIso8601String(),
      'signatures': instance.signatures,
    };

SignatureModel _$SignatureModelFromJson(Map<String, dynamic> json) =>
    SignatureModel(
      signerUsername: json['signer_username'] as String,
      signerId: json['signer_id'] as String? ?? '',
      authorityScore: (json['authority_score'] as num).toInt(),
      signedAt: json['signed_at'] as String,
    );

Map<String, dynamic> _$SignatureModelToJson(SignatureModel instance) =>
    <String, dynamic>{
      'signer_username': instance.signerUsername,
      'signer_id': instance.signerId,
      'authority_score': instance.authorityScore,
      'signed_at': instance.signedAt,
    };

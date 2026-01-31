import '../../data/repositories/contract_repository.dart';
import '../entities/contract.dart';

/// Use case for signing/approving a contract
class SignContractUseCase {
  final ContractRepository _contractRepository;
  
  SignContractUseCase({required ContractRepository contractRepository})
      : _contractRepository = contractRepository;
  
  /// Execute contract approval
  Future<SignContractResult> execute(String contractId) async {
    try {
      // Get contract details first
      final contract = await _contractRepository.getContractById(contractId);
      
      if (contract == null) {
        return SignContractResult.failure('Contract not found');
      }
      
      // Validate contract state
      if (contract.status != ContractStatusEnum.pendingApproval) {
        return SignContractResult.failure('Contract is not pending approval');
      }
      
      if (contract.isExpired) {
        return SignContractResult.failure('Contract has expired');
      }
      
      // Approve the contract
      final success = await _contractRepository.approveContract(contractId);
      
      if (success) {
        // Fetch updated contract
        final updatedContract = await _contractRepository.getContractById(contractId);
        return SignContractResult.success(updatedContract);
      } else {
        return SignContractResult.failure('Failed to approve contract');
      }
    } catch (e) {
      return SignContractResult.failure('Error: ${e.toString()}');
    }
  }
  
  /// Execute contract rejection
  Future<SignContractResult> reject(String contractId, String reason) async {
    try {
      final contract = await _contractRepository.getContractById(contractId);
      
      if (contract == null) {
        return SignContractResult.failure('Contract not found');
      }
      
      if (contract.status != ContractStatusEnum.pendingApproval) {
        return SignContractResult.failure('Contract is not pending approval');
      }
      
      final success = await _contractRepository.rejectContract(contractId, reason);
      
      if (success) {
        final updatedContract = await _contractRepository.getContractById(contractId);
        return SignContractResult.success(updatedContract);
      } else {
        return SignContractResult.failure('Failed to reject contract');
      }
    } catch (e) {
      return SignContractResult.failure('Error: ${e.toString()}');
    }
  }
}

/// Result of sign contract operation
class SignContractResult {
  final bool isSuccess;
  final Contract? contract;
  final String? errorMessage;
  
  const SignContractResult._({
    required this.isSuccess,
    this.contract,
    this.errorMessage,
  });
  
  factory SignContractResult.success(Contract? contract) {
    return SignContractResult._(isSuccess: true, contract: contract);
  }
  
  factory SignContractResult.failure(String message) {
    return SignContractResult._(isSuccess: false, errorMessage: message);
  }
}

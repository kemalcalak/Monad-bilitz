import '../../data/repositories/hierarchy_repository.dart';
import '../entities/user.dart';

/// Use case for approving decisions based on hierarchy
class ApproveDecisionUseCase {
  final HierarchyRepository _hierarchyRepository;
  
  ApproveDecisionUseCase({required HierarchyRepository hierarchyRepository})
      : _hierarchyRepository = hierarchyRepository;
  
  /// Check if user can approve for target
  Future<ApproveDecisionResult> canApprove({
    required String approverId,
    required String targetId,
  }) async {
    try {
      final approver = await _hierarchyRepository.getMemberById(approverId);
      final target = await _hierarchyRepository.getMemberById(targetId);
      
      if (approver == null) {
        return ApproveDecisionResult.failure('Approver not found');
      }
      
      if (target == null) {
        return ApproveDecisionResult.failure('Target not found');
      }
      
      if (!approver.isActive) {
        return ApproveDecisionResult.failure('Approver is not active');
      }
      
      if (!target.isActive) {
        return ApproveDecisionResult.failure('Target is not active');
      }
      
      final canApprove = approver.canApproveFor(target);
      
      if (canApprove) {
        return ApproveDecisionResult.success(
          message: '${approver.name} can approve for ${target.name}',
        );
      } else {
        return ApproveDecisionResult.failure(
          '${approver.name} does not have authority to approve for ${target.name}',
        );
      }
    } catch (e) {
      return ApproveDecisionResult.failure('Error: ${e.toString()}');
    }
  }
  
  /// Get approval chain for a decision
  Future<List<User>> getApprovalChain(String userId) async {
    try {
      return await _hierarchyRepository.getSupervisorsChain(userId);
    } catch (e) {
      return [];
    }
  }
  
  /// Find the lowest level approver for a decision
  Future<User?> findLowestLevelApprover(String userId, int requiredLevel) async {
    try {
      final chain = await getApprovalChain(userId);
      
      for (final supervisor in chain) {
        if (supervisor.level <= requiredLevel && supervisor.isActive) {
          return supervisor;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Result of approve decision check
class ApproveDecisionResult {
  final bool isSuccess;
  final String? message;
  final String? errorMessage;
  
  const ApproveDecisionResult._({
    required this.isSuccess,
    this.message,
    this.errorMessage,
  });
  
  factory ApproveDecisionResult.success({String? message}) {
    return ApproveDecisionResult._(isSuccess: true, message: message);
  }
  
  factory ApproveDecisionResult.failure(String message) {
    return ApproveDecisionResult._(isSuccess: false, errorMessage: message);
  }
}

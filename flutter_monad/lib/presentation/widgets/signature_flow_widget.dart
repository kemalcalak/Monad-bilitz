import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/hierarchy_constants.dart';
import '../../domain/entities/user.dart';

/// Widget for displaying signature flow and approval chain
class SignatureFlowWidget extends StatelessWidget {
  final List<User> approvers;
  final List<String> approvedByIds;
  final String? currentUserId;
  
  const SignatureFlowWidget({
    super.key,
    required this.approvers,
    required this.approvedByIds,
    this.currentUserId,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Approval Flow',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.headingColor,
            ),
          ),
          const SizedBox(height: 16),
          ...approvers.asMap().entries.map((entry) {
            final index = entry.key;
            final approver = entry.value;
            final isApproved = approvedByIds.contains(approver.id);
            final isCurrentUser = currentUserId == approver.id;
            final isLast = index == approvers.length - 1;
            
            return _buildApproverStep(
              approver: approver,
              isApproved: isApproved,
              isCurrentUser: isCurrentUser,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildApproverStep({
    required User approver,
    required bool isApproved,
    required bool isCurrentUser,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildStepIndicator(isApproved, isCurrentUser),
            if (!isLast) _buildConnectorLine(isApproved),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildApproverInfo(approver, isApproved, isCurrentUser),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStepIndicator(bool isApproved, bool isCurrentUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isApproved
            ? AppTheme.successColor
            : isCurrentUser
                ? AppTheme.accentColor
                : AppTheme.dividerColor,
        shape: BoxShape.circle,
        border: isCurrentUser && !isApproved
            ? Border.all(color: AppTheme.accentColor, width: 2)
            : null,
      ),
      child: Center(
        child: isApproved
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : isCurrentUser
                ? const Icon(Icons.person, color: Colors.white, size: 18)
                : const Icon(Icons.circle, color: AppTheme.bodyTextColor, size: 8),
      ),
    );
  }
  
  Widget _buildConnectorLine(bool isApproved) {
    return Container(
      width: 2,
      height: 40,
      color: isApproved ? AppTheme.successColor : AppTheme.dividerColor,
    );
  }
  
  Widget _buildApproverInfo(User approver, bool isApproved, bool isCurrentUser) {
    final levelColor = Color(HierarchyConstants.levelColors[approver.level] ?? 0xFF666666);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppTheme.accentColor.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentUser ? AppTheme.accentColor.withValues(alpha: 0.3) : AppTheme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                approver.name.isNotEmpty ? approver.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: levelColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      approver.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.headingColor,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  approver.role,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.bodyTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (isApproved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: AppTheme.successColor, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Signed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

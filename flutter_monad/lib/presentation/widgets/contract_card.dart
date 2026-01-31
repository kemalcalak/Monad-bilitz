import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/contract.dart';

/// Card widget for displaying contract information
class ContractCard extends StatelessWidget {
  final Contract contract;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  
  const ContractCard({
    super.key,
    required this.contract,
    this.onTap,
    this.onApprove,
    this.onReject,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildDescription(),
              const SizedBox(height: 16),
              _buildProgress(),
              if (contract.isPending) ...[
                const SizedBox(height: 16),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contract.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.headingColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${_formatDate(contract.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.bodyTextColor,
                ),
              ),
            ],
          ),
        ),
        _buildStatusChip(),
      ],
    );
  }
  
  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(contract.status.colorValue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(contract.status.colorValue).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        contract.status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(contract.status.colorValue),
        ),
      ),
    );
  }
  
  Widget _buildDescription() {
    if (contract.description == null) return const SizedBox.shrink();
    
    return Text(
      contract.description!,
      style: const TextStyle(
        fontSize: 14,
        color: AppTheme.bodyTextColor,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
  
  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Approval Progress',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.bodyTextColor.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '${contract.approvedByIds.length}/${contract.requiredApproverIds.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.headingColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: contract.approvalProgress,
          backgroundColor: AppTheme.dividerColor,
          valueColor: AlwaysStoppedAnimation<Color>(
            contract.approvalProgress == 1.0
                ? AppTheme.successColor
                : AppTheme.accentColor,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
  
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
            ),
            child: const Text('Reject'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Approve'),
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

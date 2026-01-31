import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/contract.dart';
import '../blocs/contract_bloc/contract_bloc.dart';
import '../widgets/contract_card.dart';

/// Contracts page - List and manage contracts
class ContractsPage extends StatefulWidget {
  const ContractsPage({super.key});

  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentFilter = 'ALL';

  final List<Map<String, String>> _filters = [
    {'key': 'ALL', 'label': 'All'},
    {'key': 'PENDING_APPROVAL', 'label': 'Pending'},
    {'key': 'APPROVED', 'label': 'Approved'},
    {'key': 'REJECTED', 'label': 'Rejected'},
    {'key': 'DRAFT', 'label': 'Drafts'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadContracts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _currentFilter = _filters[_tabController.index]['key']!;
    });
    _loadContracts();
  }

  void _loadContracts() {
    final status = _currentFilter == 'ALL' ? null : _currentFilter;
    context.read<ContractBloc>().add(ContractsLoadRequested(status: status));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Contracts'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.headingColor,
          unselectedLabelColor: AppTheme.bodyTextColor,
          indicatorColor: AppTheme.buttonColor,
          tabs: _filters.map((f) => Tab(text: f['label'])).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContracts,
          ),
        ],
      ),
      body: BlocBuilder<ContractBloc, ContractState>(
        builder: (context, state) {
          if (state is ContractLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ContractsLoaded) {
            if (state.contracts.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: state.contracts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final contract = state.contracts[index];
                return ContractCard(
                  contract: contract,
                  onTap: () => _showContractDetail(contract),
                  onApprove: contract.isPending
                      ? () => _approveContract(contract.id)
                      : null,
                  onReject: contract.isPending
                      ? () => _showRejectDialog(contract.id)
                      : null,
                );
              },
            );
          }

          if (state is ContractError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadContracts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateContractDialog,
        backgroundColor: AppTheme.buttonColor,
        icon: const Icon(Icons.add),
        label: const Text('New Contract'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: AppTheme.bodyTextColor),
          const SizedBox(height: 16),
          const Text(
            'No contracts found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.headingColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new contract to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.bodyTextColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showContractDetail(Contract contract) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                contract.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.headingColor,
                ),
              ),
              const SizedBox(height: 8),
              if (contract.description != null) ...[
                Text(
                  contract.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.bodyTextColor,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Status', contract.status.displayName),
              _buildDetailRow('Created', _formatDate(contract.createdAt)),
              _buildDetailRow('Content Hash', contract.contentHash.substring(0, 16) + '...'),
              _buildDetailRow('Approvals', '${contract.approvedByIds.length}/${contract.requiredApproverIds.length}'),
              const SizedBox(height: 24),
              if (contract.isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRejectDialog(contract.id);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveContract(contract.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.bodyTextColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.headingColor,
            ),
          ),
        ],
      ),
    );
  }

  void _approveContract(String contractId) {
    context.read<ContractBloc>().add(ContractApproveRequested(contractId: contractId));
  }

  void _showRejectDialog(String contractId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Contract'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ContractBloc>().add(
                ContractRejectRequested(
                  contractId: contractId,
                  reason: controller.text,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showCreateContractDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Contract'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ContractBloc>().add(
                ContractCreateRequested(
                  title: titleController.text,
                  contentHash: 'hash_${DateTime.now().millisecondsSinceEpoch}',
                  requiredApproverIds: [],
                  minApprovalLevel: 2,
                  description: descController.text.isNotEmpty ? descController.text : null,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/hierarchy_constants.dart';
import '../../data/models/hierarchy_model.dart';
import '../blocs/hierarchy_bloc/hierarchy_bloc.dart';

/// Hierarchy page - Organization tree visualization
class HierarchyPage extends StatefulWidget {
  const HierarchyPage({super.key});

  @override
  State<HierarchyPage> createState() => _HierarchyPageState();
}

class _HierarchyPageState extends State<HierarchyPage> {
  @override
  void initState() {
    super.initState();
    _loadHierarchy();
  }

  void _loadHierarchy() {
    context.read<HierarchyBloc>().add(const HierarchyLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Organization Hierarchy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHierarchy,
          ),
        ],
      ),
      body: BlocBuilder<HierarchyBloc, HierarchyState>(
        builder: (context, state) {
          if (state is HierarchyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HierarchyTreeLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.stats != null) _buildStatsRow(state.stats!),
                  const SizedBox(height: 24),
                  const Text(
                    'Organization Structure',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.headingColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHierarchyTree(state.tree),
                ],
              ),
            );
          }

          if (state is HierarchyError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadHierarchy,
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
        onPressed: _showAddMemberDialog,
        backgroundColor: AppTheme.buttonColor,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
    );
  }

  Widget _buildStatsRow(HierarchyStatsModel stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Total Members', stats.totalMembers.toString()),
          ),
          Container(width: 1, height: 40, color: AppTheme.dividerColor),
          Expanded(
            child: _buildStatItem('Active', stats.activeMembers.toString()),
          ),
          Container(width: 1, height: 40, color: AppTheme.dividerColor),
          Expanded(
            child: _buildStatItem('Pending Actions', stats.pendingContracts.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.headingColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.bodyTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHierarchyTree(HierarchyNodeModel node, {int depth = 0}) {
    final levelColor = Color(HierarchyConstants.levelColors[node.level] ?? 0xFF666666);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNodeCard(node, levelColor, depth),
        if (node.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: node.children
                  .map((child) => _buildHierarchyTree(child, depth: depth + 1))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildNodeCard(HierarchyNodeModel node, Color levelColor, int depth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (depth > 0) ...[
            Container(
              width: 20,
              height: 2,
              color: AppTheme.dividerColor,
            ),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        node.name.isNotEmpty ? node.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                        Text(
                          node.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.headingColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: levelColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                node.role,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: levelColor,
                                ),
                              ),
                            ),
                            if (node.children.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${node.descendantsCount} subordinates',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.bodyTextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!node.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.bodyTextColor),
                    onPressed: () => _showMemberOptions(node),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(HierarchyNodeModel node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                context.read<HierarchyBloc>().add(
                  HierarchyMemberDetailRequested(memberId: node.id),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Subordinate'),
              onTap: () {
                Navigator.pop(context);
                _showAddMemberDialog(supervisorId: node.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Address'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address copied')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog({String? supervisorId}) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    int selectedLevel = HierarchyConstants.levelEmployee;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Team Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Wallet Address'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedLevel,
                decoration: const InputDecoration(labelText: 'Role Level'),
                items: HierarchyConstants.levelNames.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedLevel = value);
                  }
                },
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
                context.read<HierarchyBloc>().add(
                  HierarchyMemberAddRequested(
                    name: nameController.text,
                    address: addressController.text,
                    level: selectedLevel,
                    supervisorId: supervisorId ?? '',
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/hierarchy_constants.dart';
import '../../main.dart';
import '../blocs/auth_bloc/auth_bloc.dart';
import '../blocs/contract_bloc/contract_bloc.dart';
import '../blocs/hierarchy_bloc/hierarchy_bloc.dart';
import '../../domain/entities/contract.dart';
import '../widgets/contract_card.dart';

/// Dashboard page - Main entry point after login
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Navigation callback to switch tabs
  void Function(int)? _onNavigateToTab;

  void setNavigationCallback(void Function(int) callback) {
    _onNavigateToTab = callback;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<ContractBloc>().add(const ContractsLoadRequested(status: 'pending'));
    context.read<HierarchyBloc>().add(const HierarchyLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 32),
              _buildKPISection(),
              const SizedBox(height: 32),
              _buildOverviewSection(),
              const SizedBox(height: 32),
              _buildPendingApprovalsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;
          final levelColor = Color(HierarchyConstants.levelColors[user.level] ?? 0xFF666666);

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: levelColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back,', style: TextStyle(fontSize: 14, color: AppTheme.bodyTextColor)),
                      const SizedBox(height: 4),
                      Text(
                        user.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.headingColor),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.role,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: levelColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // KPI Section with Syncfusion Gauges
  Widget _buildKPISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Metrics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.headingColor),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTimeSavedKPI()),
            const SizedBox(width: 16),
            Expanded(child: _buildIssuesResolvedKPI()),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSavedKPI() {
    return BlocBuilder<ContractBloc, ContractState>(
      builder: (context, state) {
        // Derive time saved from completed contracts (3 hours per completed contract)
        int completedCount = 0;
        if (state is ContractsLoaded) {
          completedCount = state.contracts.where((c) => c.status == ContractStatusEnum.approved).length;
        }
        final double timeSavedHours = completedCount * 3.0;
        const double targetHours = 200.0;
        final double percentage = (timeSavedHours / targetHours * 100).clamp(0, 100).toDouble();
        return _buildTimeSavedGauge(timeSavedHours, targetHours, percentage);
      },
    );
  }

  Widget _buildTimeSavedGauge(double timeSavedHours, double targetHours, double percentage) {

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer, color: Color(0xFF4CAF50), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Kazanılan Zaman',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.bodyTextColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  startAngle: 180,
                  endAngle: 0,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.15,
                    color: Color(0xFFE8E8E8),
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: percentage,
                      width: 0.15,
                      sizeUnit: GaugeSizeUnit.factor,
                      gradient: const SweepGradient(colors: [Color(0xFF81C784), Color(0xFF4CAF50)]),
                      cornerStyle: CornerStyle.bothCurve,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${timeSavedHours.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                          ),
                          const Text('saat', style: TextStyle(fontSize: 12, color: AppTheme.bodyTextColor)),
                        ],
                      ),
                      angle: 90,
                      positionFactor: 0.1,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: const Color(0xFFE8E8E8),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text('Hedef: $targetHours saat', style: const TextStyle(fontSize: 11, color: AppTheme.bodyTextColor)),
        ],
      ),
    );
  }

  Widget _buildIssuesResolvedKPI() {
    return BlocBuilder<ContractBloc, ContractState>(
      builder: (context, state) {
        int totalContracts = 0;
        int completedContracts = 0;
        if (state is ContractsLoaded) {
          totalContracts = state.contracts.length;
          completedContracts = state.contracts.where((c) => c.status == ContractStatusEnum.approved).length;
        }
        final int issuesResolved = completedContracts;
        final int totalIssues = totalContracts > 0 ? totalContracts : 1;
        final double percentage = (issuesResolved / totalIssues * 100).clamp(0, 100).toDouble();
        return _buildIssuesResolvedGauge(issuesResolved, totalIssues, percentage);
      },
    );
  }

  Widget _buildIssuesResolvedGauge(int issuesResolved, int totalIssues, double percentage) {

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF2196F3), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Çözülen Sorunlar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.bodyTextColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  startAngle: 180,
                  endAngle: 0,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.15,
                    color: Color(0xFFE8E8E8),
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: percentage.toDouble(),
                      width: 0.15,
                      sizeUnit: GaugeSizeUnit.factor,
                      gradient: const SweepGradient(colors: [Color(0xFF64B5F6), Color(0xFF2196F3)]),
                      cornerStyle: CornerStyle.bothCurve,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$issuesResolved',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2196F3)),
                          ),
                          const Text('çözüldü', style: TextStyle(fontSize: 12, color: AppTheme.bodyTextColor)),
                        ],
                      ),
                      angle: 90,
                      positionFactor: 0.1,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: const Color(0xFFE8E8E8),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text('Toplam: $totalIssues sorun', style: const TextStyle(fontSize: 11, color: AppTheme.bodyTextColor)),
        ],
      ),
    );
  }

  // Overview Section with clickable cards
  Widget _buildOverviewSection() {
    return BlocBuilder<HierarchyBloc, HierarchyState>(
      builder: (context, state) {
        if (state is HierarchyTreeLoaded && state.stats != null) {
          final stats = state.stats!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.headingColor),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildClickableStatCard(
                      'Team Members',
                      stats.activeMembers.toString(),
                      Icons.people,
                      const Color(0xFF9C27B0),
                      onTap: () {
                        // Navigate to Hierarchy page (index 2)
                        _navigateToTab(2);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildClickableStatCard(
                      'Pending Contracts',
                      stats.pendingContracts.toString(),
                      Icons.description,
                      const Color(0xFFFF9800),
                      onTap: () {
                        // Navigate to Contracts page (index 1) with pending filter
                        _navigateToTab(1);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildClickableStatCard(
                      'Pending Approvals',
                      stats.pendingSignatures.toString(),
                      Icons.draw,
                      const Color(0xFFF44336),
                      onTap: () {
                        // Scroll to pending approvals section
                        _scrollToPendingApprovals();
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildClickableStatCard(
    String title,
    String value,
    IconData icon,
    Color accentColor, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.bodyTextColor.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentColor),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.bodyTextColor)),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(int index) {
    // Find the MainNavigationPage state and change tab
    final mainNavState = context.findAncestorStateOfType<MainNavigationPageState>();
    mainNavState?.setTab(index);
  }

  void _scrollToPendingApprovals() {
    // Scroll to the pending approvals section
    Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // Pending Approvals Section
  Widget _buildPendingApprovalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pending Approvals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.headingColor),
            ),
            TextButton.icon(
              onPressed: () => _navigateToTab(1),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BlocBuilder<ContractBloc, ContractState>(
          builder: (context, state) {
            if (state is ContractLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ContractsLoaded) {
              // Filter to show only pending contracts/signatures
              final pendingContracts = state.contracts
                  .where((c) => c.status == ContractStatusEnum.pendingApproval)
                  .take(5)
                  .toList();

              if (pendingContracts.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle_outline, size: 48, color: AppTheme.successColor),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'All caught up!',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.headingColor),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'No pending approvals or signatures',
                          style: TextStyle(fontSize: 14, color: AppTheme.bodyTextColor),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingContracts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final contract = pendingContracts[index];
                  return ContractCard(
                    contract: contract,
                    onApprove: () {
                      context.read<ContractBloc>().add(ContractApproveRequested(contractId: contract.id));
                    },
                    onReject: () {
                      _showRejectDialog(contract.id);
                    },
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  void _showRejectDialog(String contractId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Contract'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter rejection reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<ContractBloc>().add(
                ContractRejectRequested(contractId: contractId, reason: controller.text),
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
}

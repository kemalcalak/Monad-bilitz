import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/hierarchy_constants.dart';
import '../../data/models/hierarchy_model.dart';
import '../blocs/hierarchy_bloc/hierarchy_bloc.dart';

// Blockchain düğüm modeli - Backend'den gelecek veri yapısı
class BlockchainNode {
  final String id;
  final String name;
  final String? parentId;  // Parent node'un ID'si
  final String? parentName; // Parent node'un adı (graph için)
  final String walletAddress;
  final int level;  // 0: CEO, 1: Director, 2: Manager, 3: TeamLead, 4: Employee
  final String role;
  final bool isActive;
  final int childrenCount;

  BlockchainNode({
    required this.id,
    required this.name,
    this.parentId,
    this.parentName,
    required this.walletAddress,
    required this.level,
    required this.role,
    this.isActive = true,
    this.childrenCount = 0,
  });

  // JSON'dan oluşturucu - Backend API'den gelen veri için
  factory BlockchainNode.fromJson(Map<String, dynamic> json) {
    return BlockchainNode(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
      parentName: json['parent_name'] as String?,
      walletAddress: json['wallet_address'] as String,
      level: json['level'] as int,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      childrenCount: json['children_count'] as int? ?? 0,
    );
  }

  // JSON'a dönüştürücü
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'parent_name': parentName,
      'wallet_address': walletAddress,
      'level': level,
      'role': role,
      'is_active': isActive,
      'children_count': childrenCount,
    };
  }

  // Node tipini level'a göre belirle (graph görselleştirmesi için)
  String get nodeType {
    if (level == 0) return 'ceo';
    if (level == 1) return 'director';
    if (level == 2) return 'manager';
    if (level == 3) return 'team_lead';
    return 'employee';
  }
}

/// Hierarchy page - Organization tree visualization with blockchain style
class HierarchyPage extends StatefulWidget {
  const HierarchyPage({super.key});

  @override
  State<HierarchyPage> createState() => _HierarchyPageState();
}

class _HierarchyPageState extends State<HierarchyPage> {
  List<BlockchainNode> _nodes = [];
  String? _selectedFilterNode;

  @override
  void initState() {
    super.initState();
    _loadHierarchy();
  }

  void _loadHierarchy() {
    context.read<HierarchyBloc>().add(const HierarchyLoadRequested());
  }

  // HierarchyNodeModel'den BlockchainNode listesi oluştur
  List<BlockchainNode> _convertToBlockchainNodes(HierarchyNodeModel root) {
    List<BlockchainNode> nodes = [];

    void traverse(HierarchyNodeModel node, String? parentName) {
      nodes.add(BlockchainNode(
        id: node.id,
        name: node.name,
        parentId: node.supervisorId,
        parentName: parentName,
        walletAddress: node.address,
        level: node.level,
        role: node.role,
        isActive: node.isActive,
        childrenCount: node.children.length,
      ));

      for (final child in node.children) {
        traverse(child, node.name);
      }
    }

    traverse(root, null);
    return nodes;
  }

  List<BlockchainNode> _getFilteredNodes() {
    if (_selectedFilterNode == null || _nodes.isEmpty) {
      return _nodes;
    }

    final selectedNode = _nodes.firstWhere(
      (n) => n.name == _selectedFilterNode,
      orElse: () => _nodes.first,
    );

    Set<String> connectedNodes = {};
    String? currentParent = selectedNode.parentName;
    connectedNodes.add(selectedNode.name);

    while (currentParent != null) {
      connectedNodes.add(currentParent);
      final parentNode = _nodes.firstWhere(
        (n) => n.name == currentParent,
        orElse: () => BlockchainNode(
          id: '',
          name: '',
          walletAddress: '',
          level: 0,
          role: '',
        ),
      );
      currentParent = parentNode.parentName;
    }

    void findChildren(String nodeName) {
      for (final node in _nodes) {
        if (node.parentName == nodeName && !connectedNodes.contains(node.name)) {
          connectedNodes.add(node.name);
          findChildren(node.name);
        }
      }
    }

    findChildren(selectedNode.name);

    return _nodes.where((n) => connectedNodes.contains(n.name)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: BlocBuilder<HierarchyBloc, HierarchyState>(
        builder: (context, state) {
          if (state is HierarchyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HierarchyTreeLoaded) {
            // HierarchyNodeModel'i BlockchainNode listesine dönüştür
            _nodes = _convertToBlockchainNodes(state.tree);
            final filteredNodes = _getFilteredNodes();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ağ Hiyerarşisi',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadHierarchy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Hiyerarşi Görselleştirmesi (tam genişlik)
                    Expanded(
                      child: _buildHierarchyContainer(filteredNodes),
                    ),
                  ],
                ),
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

  Widget _buildHierarchyContainer(List<BlockchainNode> filteredNodes) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filtreleme başlığı
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildFilterDropdown(),
          ),

          // Ağaç görünümü
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildBlockchainGraph(filteredNodes),
            ),
          ),

          // Alt bilgi (legend)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('CEO', const Color(0xFF4F46E5)),
                const SizedBox(width: 12),
                _buildLegendItem('Director', const Color(0xFF7C3AED)),
                const SizedBox(width: 12),
                _buildLegendItem('Manager', const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _buildLegendItem('Lead', const Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                _buildLegendItem('Employee', const Color(0xFF64748B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Color(0xFF666666), size: 20),
          const SizedBox(width: 12),
          const Text(
            'Filter Node:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedFilterNode,
                hint: const Text(
                  'All Network',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF666666)),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                dropdownColor: const Color(0xFFFFFFFF),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'All Network',
                      style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                  ),
                  ..._nodes.map(
                    (node) => DropdownMenuItem<String?>(
                      value: node.name,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getNodeColor(node.nodeType),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            node.name,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFilterNode = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNodeColor(String type) {
    switch (type) {
      case 'ceo':
        return const Color(0xFF4F46E5); // Indigo 600
      case 'director':
        return const Color(0xFF7C3AED); // Violet 600
      case 'manager':
        return const Color(0xFF10B981); // Emerald 500
      case 'team_lead':
        return const Color(0xFFF59E0B); // Amber 500
      default:
        return const Color(0xFF64748B); // Slate 500
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildBlockchainGraph(List<BlockchainNode> nodes) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: BlockchainTreePainter(nodes: nodes),
          child: const SizedBox.expand(),
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
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
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

// Custom painter for blockchain tree visualization
class BlockchainTreePainter extends CustomPainter {
  final List<BlockchainNode> nodes;

  BlockchainTreePainter({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()..style = PaintingStyle.fill;

    final Map<String, Offset> positions = {};
    final levels = _calculateLevels();

    for (var level = 0; level < levels.length; level++) {
      final nodesAtLevel = levels[level];
      final yPosition = 60.0 +
          level * (size.height - 120) / (levels.length > 1 ? levels.length - 1 : 1);

      for (var i = 0; i < nodesAtLevel.length; i++) {
        final xPosition = (size.width / (nodesAtLevel.length + 1)) * (i + 1);
        positions[nodesAtLevel[i].name] = Offset(xPosition, yPosition);
      }
    }

    // Bağlantı çizgilerini çiz
    for (final node in nodes) {
      if (node.parentName != null && positions.containsKey(node.parentName)) {
        final start = positions[node.parentName]!;
        final end = positions[node.name]!;

        final path = Path();
        path.moveTo(start.dx, start.dy);
        final midY = (start.dy + end.dy) / 2;
        path.cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);

        canvas.drawPath(path, paint);
      }
    }

    // Node'ları çiz
    for (final node in nodes) {
      if (positions.containsKey(node.name)) {
        final pos = positions[node.name]!;
        final radius = _getNodeRadius(node.nodeType);

        nodePaint.color = _getNodeColor(node.nodeType);

        // Inactive nodes için farklı görünüm
        if (!node.isActive) {
          nodePaint.color = const Color(0xFFCCCCCC);
        }

        canvas.drawCircle(pos, radius + 2, Paint()..color = const Color(0xFFFFFFFF));
        canvas.drawCircle(pos, radius, nodePaint);

        final textPainter = TextPainter(
          text: TextSpan(
            text: node.name,
            style: TextStyle(
              color: node.isActive ? const Color(0xFF666666) : const Color(0xFFAAAAAA),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(pos.dx - textPainter.width / 2, pos.dy + radius + 8),
        );
      }
    }
  }

  List<List<BlockchainNode>> _calculateLevels() {
    final Map<String, int> nodeLevels = {};
    final List<List<BlockchainNode>> levels = [];

    for (final node in nodes) {
      if (node.parentName == null) {
        nodeLevels[node.name] = 0;
      }
    }

    var changed = true;
    while (changed) {
      changed = false;
      for (final node in nodes) {
        if (node.parentName != null &&
            nodeLevels.containsKey(node.parentName) &&
            !nodeLevels.containsKey(node.name)) {
          nodeLevels[node.name] = nodeLevels[node.parentName]! + 1;
          changed = true;
        }
      }
    }

    final maxLevel =
        nodeLevels.values.isEmpty ? 0 : nodeLevels.values.reduce((a, b) => a > b ? a : b);
    for (var i = 0; i <= maxLevel; i++) {
      levels.add(nodes.where((n) => nodeLevels[n.name] == i).toList());
    }

    return levels;
  }

  double _getNodeRadius(String type) {
    switch (type) {
      case 'ceo':
        return 22;
      case 'director':
        return 18;
      case 'manager':
        return 16;
      case 'team_lead':
        return 14;
      default:
        return 12;
    }
  }

  Color _getNodeColor(String type) {
    switch (type) {
      case 'ceo':
        return const Color(0xFF4F46E5); // Indigo 600
      case 'director':
        return const Color(0xFF7C3AED); // Violet 600
      case 'manager':
        return const Color(0xFF10B981); // Emerald 500
      case 'team_lead':
        return const Color(0xFFF59E0B); // Amber 500
      default:
        return const Color(0xFF64748B); // Slate 500
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blockchain Yönetim Paneli',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        fontFamily: 'Roboto',
      ),
      home: const BlockchainPanelPage(),
    );
  }
}

// Blockchain düğüm modeli
class BlockchainNode {
  final String name;
  final String? parent;
  final int connections;
  final String type;

  BlockchainNode({
    required this.name,
    this.parent,
    required this.connections,
    required this.type,
  });
}

// Akıllı kontrat imza modeli
class SmartContractSignature {
  final String contractName;
  final String description;
  final DateTime signedAt;

  SmartContractSignature({
    required this.contractName,
    required this.description,
    required this.signedAt,
  });
}

class BlockchainPanelPage extends StatefulWidget {
  const BlockchainPanelPage({super.key});

  @override
  State<BlockchainPanelPage> createState() => _BlockchainPanelPageState();
}

class _BlockchainPanelPageState extends State<BlockchainPanelPage> {
  late List<BlockchainNode> _nodes;
  String? _selectedFilterNode;
  late List<SmartContractSignature> _signatures;

  @override
  void initState() {
    super.initState();
    _initializeNodes();
    _initializeSignatures();
  }

  void _initializeNodes() {
    _nodes = [
      BlockchainNode(name: 'Genesis', parent: null, connections: 5, type: 'root'),
      BlockchainNode(name: 'Block-1', parent: 'Genesis', connections: 3, type: 'validator'),
      BlockchainNode(name: 'Block-2', parent: 'Genesis', connections: 4, type: 'validator'),
      BlockchainNode(name: 'Block-3', parent: 'Genesis', connections: 2, type: 'node'),
      BlockchainNode(name: 'Node-A', parent: 'Block-1', connections: 2, type: 'node'),
      BlockchainNode(name: 'Node-B', parent: 'Block-1', connections: 1, type: 'node'),
      BlockchainNode(name: 'Node-C', parent: 'Block-2', connections: 3, type: 'validator'),
      BlockchainNode(name: 'Node-D', parent: 'Block-2', connections: 2, type: 'node'),
      BlockchainNode(name: 'Node-E', parent: 'Block-3', connections: 1, type: 'node'),
    ];
  }

  void _initializeSignatures() {
    _signatures = [
      SmartContractSignature(
        contractName: 'TokenSwap v2.1',
        description: 'DEX token değişim kontratı',
        signedAt: DateTime(2026, 1, 31, 10, 30),
      ),
      SmartContractSignature(
        contractName: 'NFT Marketplace',
        description: 'Dijital varlık satış platformu',
        signedAt: DateTime(2026, 1, 30, 14, 15),
      ),
      SmartContractSignature(
        contractName: 'Staking Pool',
        description: 'Likidite havuzu stake kontratı',
        signedAt: DateTime(2026, 1, 29, 09, 45),
      ),
      SmartContractSignature(
        contractName: 'Governance DAO',
        description: 'Oylama ve yönetişim sistemi',
        signedAt: DateTime(2026, 1, 28, 16, 20),
      ),
      SmartContractSignature(
        contractName: 'Bridge Protocol',
        description: 'Çapraz zincir köprü kontratı',
        signedAt: DateTime(2026, 1, 27, 11, 00),
      ),
    ];
  }

  List<BlockchainNode> _getFilteredNodes() {
    if (_selectedFilterNode == null) {
      return _nodes;
    }

    final selectedNode = _nodes.firstWhere(
      (n) => n.name == _selectedFilterNode,
      orElse: () => _nodes.first,
    );

    Set<String> connectedNodes = {};
    String? currentParent = selectedNode.parent;
    connectedNodes.add(selectedNode.name);
    
    while (currentParent != null) {
      connectedNodes.add(currentParent);
      final parentNode = _nodes.firstWhere(
        (n) => n.name == currentParent,
        orElse: () => BlockchainNode(name: '', connections: 0, type: ''),
      );
      currentParent = parentNode.parent;
    }

    void findChildren(String nodeName) {
      for (final node in _nodes) {
        if (node.parent == nodeName && !connectedNodes.contains(node.name)) {
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
    final filteredNodes = _getFilteredNodes();
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Center(
                child: Text(
                  'Ağ Hiyerarşisi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Ana içerik - 2/3 Hiyerarşi + 1/3 Signatures
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sol taraf - Ağ Hiyerarşisi (2/3)
                    Expanded(
                      flex: 2,
                      child: _buildHierarchyContainer(filteredNodes),
                    ),
                    const SizedBox(width: 24),
                    // Sağ taraf - Signatures (1/3)
                    Expanded(
                      flex: 1,
                      child: _buildSignaturesContainer(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHierarchyContainer(List<BlockchainNode> filteredNodes) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
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
                _buildLegendItem('Genesis', const Color(0xFF1A1A1A)),
                const SizedBox(width: 24),
                _buildLegendItem('Validator', const Color(0xFF444444)),
                const SizedBox(width: 24),
                _buildLegendItem('Node', const Color(0xFF888888)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturesContainer() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Signatures',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: const Color(0xFFE0E0E0)),
          
          // İmza listesi
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _signatures.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildSignatureCard(_signatures[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCard(SmartContractSignature signature) {
    final dateStr = '${signature.signedAt.day.toString().padLeft(2, '0')}.${signature.signedAt.month.toString().padLeft(2, '0')}.${signature.signedAt.year}';
    final timeStr = '${signature.signedAt.hour.toString().padLeft(2, '0')}:${signature.signedAt.minute.toString().padLeft(2, '0')}';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF8F9FA),
            const Color(0xFFFFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kontrat adı
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C853).withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  signature.contractName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Açıklama
          Text(
            signature.description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Tarih ve saat
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: const Color(0xFF999999),
              ),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time,
                size: 12,
                color: const Color(0xFF999999),
              ),
              const SizedBox(width: 4),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            color: Color(0xFF666666),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Düğüm Filtrele:',
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
                  'Tüm Ağ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF666666)),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
                dropdownColor: const Color(0xFFFFFFFF),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Tüm Ağ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  ..._nodes.map((node) => DropdownMenuItem<String?>(
                    value: node.name,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getNodeColor(node.type),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          node.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  )),
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
      case 'root':
        return const Color(0xFF1A1A1A);
      case 'validator':
        return const Color(0xFF444444);
      default:
        return const Color(0xFF888888);
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
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
      final yPosition = 60.0 + level * (size.height - 120) / (levels.length > 1 ? levels.length - 1 : 1);
      
      for (var i = 0; i < nodesAtLevel.length; i++) {
        final xPosition = (size.width / (nodesAtLevel.length + 1)) * (i + 1);
        positions[nodesAtLevel[i].name] = Offset(xPosition, yPosition);
      }
    }

    for (final node in nodes) {
      if (node.parent != null && positions.containsKey(node.parent)) {
        final start = positions[node.parent]!;
        final end = positions[node.name]!;
        
        final path = Path();
        path.moveTo(start.dx, start.dy);
        final midY = (start.dy + end.dy) / 2;
        path.cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);
        
        canvas.drawPath(path, paint);
      }
    }

    for (final node in nodes) {
      if (positions.containsKey(node.name)) {
        final pos = positions[node.name]!;
        final radius = _getNodeRadius(node.type);
        
        nodePaint.color = _getNodeColor(node.type);
        
        canvas.drawCircle(pos, radius + 2, Paint()..color = const Color(0xFFFFFFFF));
        canvas.drawCircle(pos, radius, nodePaint);
        
        final textPainter = TextPainter(
          text: TextSpan(
            text: node.name,
            style: const TextStyle(
              color: Color(0xFF666666),
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
      if (node.parent == null) {
        nodeLevels[node.name] = 0;
      }
    }

    var changed = true;
    while (changed) {
      changed = false;
      for (final node in nodes) {
        if (node.parent != null && 
            nodeLevels.containsKey(node.parent) && 
            !nodeLevels.containsKey(node.name)) {
          nodeLevels[node.name] = nodeLevels[node.parent]! + 1;
          changed = true;
        }
      }
    }

    final maxLevel = nodeLevels.values.isEmpty ? 0 : nodeLevels.values.reduce((a, b) => a > b ? a : b);
    for (var i = 0; i <= maxLevel; i++) {
      levels.add(nodes.where((n) => nodeLevels[n.name] == i).toList());
    }

    return levels;
  }

  double _getNodeRadius(String type) {
    switch (type) {
      case 'root':
        return 20;
      case 'validator':
        return 14;
      default:
        return 10;
    }
  }

  Color _getNodeColor(String type) {
    switch (type) {
      case 'root':
        return const Color(0xFF1A1A1A);
      case 'validator':
        return const Color(0xFF444444);
      default:
        return const Color(0xFF888888);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/contract.dart';
import '../blocs/contract_bloc/contract_bloc.dart';
import '../widgets/contract_card.dart';

/// Task model - JSON'dan yüklenen görev verisi
class Task {
  final String id;
  final String title;
  final String shortDescription;
  final String longDescription;
  final String priority; // critical, high, medium, low
  final bool isError;
  final String createdAt;
  HierarchyUser? assignedTo; // Atanan kullanıcı

  Task({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.longDescription,
    required this.priority,
    this.isError = false,
    required this.createdAt,
    this.assignedTo,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      shortDescription: json['short_description'] as String,
      longDescription: json['long_description'] as String,
      priority: json['priority'] as String,
      isError: json['is_error'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );
  }

  Color get priorityColor {
    switch (priority) {
      case 'critical': return const Color(0xFFEF4444);
      case 'high': return const Color(0xFFF59E0B);
      case 'medium': return const Color(0xFF3B82F6);
      case 'low': return const Color(0xFF22C55E);
      default: return const Color(0xFF666666);
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'critical': return 'Critical';
      case 'high': return 'High';
      case 'medium': return 'Medium';
      case 'low': return 'Low';
      default: return 'Unknown';
    }
  }

  Task copyWith({HierarchyUser? assignedTo}) {
    return Task(
      id: id,
      title: title,
      shortDescription: shortDescription,
      longDescription: longDescription,
      priority: priority,
      isError: isError,
      createdAt: createdAt,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}

/// Hierarchy User model - JSON'dan gelen kullanıcı verisi
class HierarchyUser {
  final String id;
  final String name;
  final String? parentId;
  final String? parentName;
  final String walletAddress;
  final int level;
  final String role;
  final bool isActive;
  final int childrenCount;

  const HierarchyUser({
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

  factory HierarchyUser.fromJson(Map<String, dynamic> json) {
    return HierarchyUser(
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

  String get levelName {
    switch (level) {
      case 0: return 'CEO';
      case 1: return 'Director';
      case 2: return 'Manager';
      case 3: return 'Team Lead';
      case 4: return 'Employee';
      default: return 'Unknown';
    }
  }

  Color get levelColor {
    switch (level) {
      case 0: return const Color(0xFF1A1A1A);
      case 1: return const Color(0xFF3B82F6);
      case 2: return const Color(0xFF22C55E);
      case 3: return const Color(0xFFF59E0B);
      case 4: return const Color(0xFF666666);
      default: return const Color(0xFF666666);
    }
  }
}

/// Assigned Task - Atanmış görev modeli
class AssignedTask {
  final Task task;
  final HierarchyUser assignee;
  final DateTime assignedAt;

  AssignedTask({
    required this.task,
    required this.assignee,
    required this.assignedAt,
  });
}

/// Contracts page - List and manage contracts
class ContractsPage extends StatefulWidget {
  const ContractsPage({super.key});

  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  List<HierarchyUser> _users = [];
  List<Task> _tasks = [];
  List<AssignedTask> _assignedTasks = [];
  bool _isLoadingUsers = true;
  bool _isLoadingTasks = true;
  
  // Filter states
  String _taskFilter = 'all'; // all, critical, high, medium, low, errors
  String _assignedTaskFilter = 'all'; // all, critical, high, medium, low
  String _userFilter = 'all'; // all, online, offline

  @override
  void initState() {
    super.initState();
    _loadContracts();
    _loadUsersFromJson();
    _loadTasksFromJson();
    
    // Parıldayan animasyon için controller
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUsersFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/sample_hierarchy_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> nodesJson = jsonData['hierarchy_nodes'] as List<dynamic>;
      
      setState(() {
        _users = nodesJson.map((node) => HierarchyUser.fromJson(node as Map<String, dynamic>)).toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      debugPrint('Error loading users: $e');
    }
  }

  Future<void> _loadTasksFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/sample_tasks_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> tasksJson = jsonData['tasks'] as List<dynamic>;
      
      setState(() {
        _tasks = tasksJson.map((task) => Task.fromJson(task as Map<String, dynamic>)).toList();
        _isLoadingTasks = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTasks = false;
      });
      debugPrint('Error loading tasks: $e');
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void _loadContracts() {
    context.read<ContractBloc>().add(const ContractsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Contracts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContracts,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container 1 - Sol (Tasks)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.buttonColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.pending_actions,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.headingColor,
                          ),
                        ),
                        const Spacer(),
                        _buildTaskFilterDropdown(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildTasksList(),
                    ),
                  ],
                ),
              ),
            ),
            

            // Container 2 - Orta (Users in Hierarchy)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.headingColor,
                          ),
                        ),
                        const Spacer(),
                        _buildUserFilterDropdown(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildUsersList(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Container 3 - Sağ (Assigned Tasks)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Contracts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.headingColor,
                          ),
                        ),
                        const Spacer(),
                        _buildAssignedTaskFilterDropdown(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppTheme.dividerColor),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildAssignedTasksList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskDialog,
        backgroundColor: AppTheme.buttonColor,
        icon: const Icon(Icons.add_task),
        label: const Text('New Task'),
      ),
    );
  }

  /// Task filter dropdown widget
  Widget _buildTaskFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _taskFilter,
          isDense: true,
          icon: const Icon(Icons.filter_list, size: 18),
          style: const TextStyle(fontSize: 12, color: AppTheme.bodyTextColor),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'errors', child: Text('🔴 Errors Only')),
            DropdownMenuItem(value: 'critical', child: Text('Critical')),
            DropdownMenuItem(value: 'high', child: Text('High')),
            DropdownMenuItem(value: 'medium', child: Text('Medium')),
            DropdownMenuItem(value: 'low', child: Text('Low')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _taskFilter = value);
            }
          },
        ),
      ),
    );
  }

  /// User filter dropdown widget
  Widget _buildUserFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _userFilter,
          isDense: true,
          icon: const Icon(Icons.filter_list, size: 18),
          style: const TextStyle(fontSize: 12, color: AppTheme.bodyTextColor),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'online', child: Text('🟢 Online')),
            DropdownMenuItem(value: 'offline', child: Text('⚫ Offline')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _userFilter = value);
            }
          },
        ),
      ),
    );
  }

  /// Assigned Task filter dropdown widget
  Widget _buildAssignedTaskFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _assignedTaskFilter,
          isDense: true,
          icon: const Icon(Icons.filter_list, size: 18),
          style: const TextStyle(fontSize: 12, color: AppTheme.bodyTextColor),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'critical', child: Text('Critical')),
            DropdownMenuItem(value: 'high', child: Text('High')),
            DropdownMenuItem(value: 'medium', child: Text('Medium')),
            DropdownMenuItem(value: 'low', child: Text('Low')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _assignedTaskFilter = value);
            }
          },
        ),
      ),
    );
  }

  /// Get filtered tasks list
  List<Task> get _filteredTasks {
    if (_taskFilter == 'all') return _tasks;
    if (_taskFilter == 'errors') return _tasks.where((t) => t.isError).toList();
    return _tasks.where((t) => t.priority == _taskFilter).toList();
  }

  /// Get filtered users list
  List<HierarchyUser> get _filteredUsers {
    if (_userFilter == 'all') return _users;
    if (_userFilter == 'online') return _users.where((u) => u.isActive).toList();
    return _users.where((u) => !u.isActive).toList();
  }

  /// Get filtered assigned tasks list
  List<AssignedTask> get _filteredAssignedTasks {
    if (_assignedTaskFilter == 'all') return _assignedTasks;
    return _assignedTasks.where((at) => at.task.priority == _assignedTaskFilter).toList();
  }

  /// Yeni görev oluşturma dialog'u
  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'medium';
    bool isError = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.buttonColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_task,
                        color: AppTheme.buttonColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Create New Task',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.headingColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Task Name
                const Text(
                  'Task Name *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.headingColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter task name',
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.buttonColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),

                const SizedBox(height: 16),

                // Short Description
                const Text(
                  'Short Description *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.headingColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter a brief description of the task',
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.buttonColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),

                const SizedBox(height: 16),

                // Priority Selection
                const Text(
                  'Priority Level',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.headingColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedPriority,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: [
                        DropdownMenuItem(
                          value: 'critical',
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFFEF4444), shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              const Text('Critical'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFFF59E0B), shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              const Text('High'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF3B82F6), shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              const Text('Medium'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'low',
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              const Text('Low'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedPriority = value);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Is Error Checkbox
                InkWell(
                  onTap: () => setDialogState(() => isError = !isError),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isError ? AppTheme.errorColor.withValues(alpha: 0.1) : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isError ? AppTheme.errorColor : AppTheme.dividerColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isError ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isError ? AppTheme.errorColor : AppTheme.bodyTextColor,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mark as Urgent Error',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.headingColor,
                                ),
                              ),
                              Text(
                                'This task will display with a blinking indicator',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.bodyTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please fill in all required fields'),
                            backgroundColor: AppTheme.errorColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                        return;
                      }

                      final newTask = Task(
                        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
                        title: titleController.text.trim(),
                        shortDescription: descriptionController.text.trim(),
                        longDescription: descriptionController.text.trim(),
                        priority: selectedPriority,
                        isError: isError,
                        createdAt: DateTime.now().toIso8601String(),
                      );

                      setState(() {
                        _tasks.insert(0, newTask);
                      });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Task created successfully'),
                          backgroundColor: AppTheme.successColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Create Task',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Görevler listesini oluştur
  Widget _buildTasksList() {
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredTasks = _filteredTasks;

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 48,
              color: AppTheme.bodyTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              _taskFilter == 'all' ? 'No tasks' : 'No matching tasks',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.bodyTextColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredTasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildTaskCard(filteredTasks[index]);
      },
    );
  }

  /// Tek bir görev kartını oluştur
  Widget _buildTaskCard(Task task) {
    return GestureDetector(
      onTap: () => _showTaskDetailPopup(task),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: task.isError 
              ? AppTheme.errorColor.withValues(alpha: 0.05) 
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isError 
                ? AppTheme.errorColor.withValues(alpha: 0.3) 
                : AppTheme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            // İkon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: task.isError 
                    ? AppTheme.errorColor.withValues(alpha: 0.1)
                    : task.priorityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                task.isError ? Icons.error_outline : Icons.task_alt,
                color: task.isError ? AppTheme.errorColor : task.priorityColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            
            // Başlık ve açıklama
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: task.isError ? AppTheme.errorColor : AppTheme.headingColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: task.priorityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.priorityLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: task.priorityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.shortDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.bodyTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Error ise parıldayan kırmızı daire
            if (task.isError) ...[
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _blinkAnimation,
                builder: (context, child) {
                  return Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.errorColor.withValues(alpha: _blinkAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.errorColor.withValues(alpha: _blinkAnimation.value * 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppTheme.bodyTextColor.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Task detay popup'ını göster
  void _showTaskDetailPopup(Task task) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: task.isError 
                          ? AppTheme.errorColor.withValues(alpha: 0.1)
                          : task.priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      task.isError ? Icons.error_outline : Icons.task_alt,
                      color: task.isError ? AppTheme.errorColor : task.priorityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.headingColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: task.priorityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.priorityLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: task.priorityColor,
                                ),
                              ),
                            ),
                            if (task.isError) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Urgent Error',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppTheme.dividerColor),
              const SizedBox(height: 20),
              
              // Short Description
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.headingColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.shortDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.bodyTextColor,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Long Description
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.headingColor,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    task.longDescription,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.bodyTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Assign Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAssignTaskDialog(task);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Görev atama dialog'unu göster
  void _showAssignTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Assign Task To User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.headingColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              Text(
                'Task: ${task.title}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.bodyTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppTheme.dividerColor),
              const SizedBox(height: 16),
              
              const Text(
                'Select User',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.headingColor,
                ),
              ),
              const SizedBox(height: 12),
              
              // Users list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _users.where((u) => u.isActive).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final activeUsers = _users.where((u) => u.isActive).toList();
                    final user = activeUsers[index];
                    return _buildAssignUserCard(task, user);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Atama için kullanıcı kartı
  Widget _buildAssignUserCard(Task task, HierarchyUser user) {
    return InkWell(
      onTap: () => _assignTaskToUser(task, user),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: user.levelColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: user.levelColor,
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
                    user.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.headingColor,
                    ),
                  ),
                  Text(
                    '${user.role} • L${user.level}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.bodyTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              color: AppTheme.buttonColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// Görevi kullanıcıya ata
  void _assignTaskToUser(Task task, HierarchyUser user) {
    final assignedTask = AssignedTask(
      task: task,
      assignee: user,
      assignedAt: DateTime.now(),
    );
    
    setState(() {
      _assignedTasks.add(assignedTask);
      // Task'ı listeden kaldır
      _tasks.removeWhere((t) => t.id == task.id);
    });
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task assigned to ${user.name}'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Atanmış görevler listesini oluştur
  Widget _buildAssignedTasksList() {
    final filteredAssigned = _filteredAssignedTasks;

    if (filteredAssigned.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: AppTheme.bodyTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              _assignedTaskFilter == 'all' ? 'No assigned tasks' : 'No matching assigned tasks',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.bodyTextColor.withValues(alpha: 0.7),
              ),
            ),
            if (_assignedTaskFilter == 'all') ...[
              const SizedBox(height: 4),
              Text(
                'Assign tasks from the Tasks panel',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.bodyTextColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredAssigned.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildAssignedTaskCard(filteredAssigned[index]);
      },
    );
  }

  /// Atanmış görev kartını oluştur
  Widget _buildAssignedTaskCard(AssignedTask assignedTask) {
    final task = assignedTask.task;
    final user = assignedTask.assignee;
    
    return GestureDetector(
      onTap: () => _showAssignedTaskDetailPopup(assignedTask),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.successColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: task.priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.assignment_turned_in,
                    color: task.priorityColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.headingColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: task.priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.priorityLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: task.priorityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: user.levelColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: user.levelColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned to: ${user.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.headingColor,
                        ),
                      ),
                      Text(
                        user.role,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.bodyTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.bodyTextColor.withValues(alpha: 0.5),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Atanmış görev detay popup'ını göster
  void _showAssignedTaskDetailPopup(AssignedTask assignedTask) {
    final task = assignedTask.task;
    final user = assignedTask.assignee;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 650),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in,
                      color: AppTheme.successColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.headingColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: task.priorityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.priorityLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: task.priorityColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Assigned',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Assignee Info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: user.levelColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: user.levelColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: user.levelColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          user.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: user.levelColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assigned To',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.bodyTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.headingColor,
                            ),
                          ),
                          Text(
                            '${user.role} • Level ${user.level}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.bodyTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppTheme.dividerColor),
              const SizedBox(height: 20),
              
              // Summary
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.headingColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.shortDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.bodyTextColor,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Details
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.headingColor,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    task.longDescription,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.bodyTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// Kullanıcı listesini oluştur
  Widget _buildUsersList() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredUsers = _filteredUsers;

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: AppTheme.bodyTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              _userFilter == 'all' ? 'No users found' : 'No ${_userFilter} users',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.bodyTextColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildUserCard(filteredUsers[index]);
      },
    );
  }

  /// Tek bir kullanıcı kartını oluştur
  Widget _buildUserCard(HierarchyUser user) {
    return GestureDetector(
      onTap: () => _showUserDetailPopup(user),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: user.isActive 
              ? AppTheme.surfaceColor 
              : AppTheme.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: user.isActive 
                ? user.levelColor.withValues(alpha: 0.3) 
                : AppTheme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: user.levelColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: user.levelColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // İsim, rol ve level
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: user.isActive ? AppTheme.headingColor : AppTheme.bodyTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        user.role,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.bodyTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.levelColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'L${user.level}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: user.levelColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status indicator
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: user.isActive ? AppTheme.successColor : AppTheme.bodyTextColor.withValues(alpha: 0.3),
              ),
            ),
            
            // Arrow icon
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppTheme.bodyTextColor.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Kullanıcı detay popup'ını göster
  void _showUserDetailPopup(HierarchyUser user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: user.levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: user.levelColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Name
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.headingColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: user.levelColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.role,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: user.levelColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppTheme.dividerColor),
              const SizedBox(height: 24),
              
              // Details
              _buildDetailItem(Icons.badge, 'ID', user.id),
              _buildDetailItem(Icons.layers, 'Level', '${user.level} (${user.levelName})'),
              _buildDetailItem(Icons.account_balance_wallet, 'Wallet', '${user.walletAddress.substring(0, 10)}...${user.walletAddress.substring(user.walletAddress.length - 8)}'),
              _buildDetailItem(Icons.supervisor_account, 'Reports To', user.parentName ?? 'None (Top Level)'),
              _buildDetailItem(Icons.people, 'Direct Reports', '${user.childrenCount}'),
              _buildDetailItem(
                user.isActive ? Icons.check_circle : Icons.cancel, 
                'Status', 
                user.isActive ? 'Active' : 'Inactive',
                valueColor: user.isActive ? AppTheme.successColor : AppTheme.errorColor,
              ),
              
              const SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.bodyTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.bodyTextColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppTheme.headingColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractList(ContractStatusEnum filterStatus) {
    return BlocBuilder<ContractBloc, ContractState>(
      builder: (context, state) {
        if (state is ContractLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ContractsLoaded) {
          final filteredContracts = state.contracts
              .where((c) => c.status == filterStatus)
              .toList();

          if (filteredContracts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: AppTheme.bodyTextColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No contracts',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.bodyTextColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: filteredContracts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final contract = filteredContracts[index];
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
                const Icon(Icons.error_outline, size: 32, color: AppTheme.errorColor),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: const TextStyle(fontSize: 12, color: AppTheme.bodyTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
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
